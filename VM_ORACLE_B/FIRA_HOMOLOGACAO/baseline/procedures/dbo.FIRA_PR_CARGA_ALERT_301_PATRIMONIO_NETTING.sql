CREATE PROCEDURE [DBO].[FIRA_PR_CARGA_ALERT_301_PATRIMONIO_NETTING] @PREGAO SMALLDATETIME, @AUX INT
AS


/*************************************************************************************************
REGRA DO ALERTA:
Clientes que tiveram o NET de BVSP ou BMF > patrimônio declarado absoluto no ultimo dia util do mes.
Onde, Netting é compra - venda de ativos do cliente.
*************************************************************************************************/


 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_PATRIMONIO_NETTING_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_PATRIMONIO_NETTING_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NULL,
	[NETTING_BVSP] [float] NULL,
	[NETTING_BMF] [float] NULL,
	[PATRIMONIO] [numeric](38, 2) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_PATRIMONIO_NETTING_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_PATRIMONIO_NETTING',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20251205'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual
declare @dt_ini_6m date = dateadd(month, datediff(month,0, dateadd(month,-7,@pregao)),0) -- primeiro dia do 6 mes anterior ao mes atual
declare @dt_fim_6m date = @dt_ini -- 1 dia do mes atual
DECLARE @DT_REF DATE = DATEADD(DAY, - @AUX, @PREGAO);

drop table if exists #PATRIMONIO_NET
DECLARE @PERCENTUAL_ACRESCIMO NUMERIC(10,2) = (SELECT [CD_PARAMETRO] FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'PERCENTUAL_PATRIMONIO')
-- NULL = mantém o patrimônio original
-- 100  = acrescenta 100%
-- 50   = acrescenta 50%
-- 20   = acrescenta 20%

SELECT P.CD_CLIENTE
,P.PATRIMONIO_ORIGINAL
,CAST(P.PATRIMONIO_ORIGINAL * (1 + ISNULL(@PERCENTUAL_ACRESCIMO, 0) / 100.0) AS NUMERIC(38,2)) AS PATRIMONIO
INTO #PATRIMONIO_NET
FROM (SELECT XX.CD_CLIENTE
,XX.TIPO
,CAST(CASE WHEN XX.TIPO = 'PF' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_SITU_PATRM) WHEN XX.TIPO = 'PJ' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_PATRM_LIQ) ELSE SUM(XX.VAL_BENS) END AS NUMERIC(38,2)) AS PATRIMONIO_ORIGINAL
FROM ST_PATRIMONIO_LIQ XX
WHERE XX.DATA = (SELECT MAX(YY.DATA) FROM ST_PATRIMONIO_LIQ YY WHERE YY.DATA >= @DT_INI AND YY.DATA < @DT_FIM AND DATEPART(WEEKDAY, YY.DATA) NOT IN (1, 7))
GROUP BY XX.CD_CLIENTE
,XX.TIPO) P;

CREATE NONCLUSTERED INDEX T1         
ON [DBO].[#PATRIMONIO_NET] ([CD_CLIENTE]) 
INCLUDE ([PATRIMONIO])         
                 
--NETTING BOVESPA
drop table if exists #BOVESPA_NET
	SELECT 
		X.[DATA],
		X.CD_CLIENTE,
		SUM(X.COMPRA) - SUM(X.VENDA) AS VOLUME_BVSP,
		ISNULL(X.PATRIMONIO,0) PATRIMONIO,
		ISNULL(X.PATRIMONIO_ORIGINAL,0) PATRIMONIO_ORIGINAL
	
	INTO #BOVESPA_NET
	FROM(
		SELECT 
			CAST(@PREGAO - @AUX AS DATE) AS [DATA],
			CO.CD_CLIENTE,
			SUM(CASE WHEN CO.CD_NATOPE = 'C' THEN VL_TOTNEG ELSE 0 END) AS COMPRA,
			SUM(CASE WHEN CO.CD_NATOPE = 'V' THEN VL_TOTNEG ELSE 0 END) AS VENDA,
			ISNULL(PAT.PATRIMONIO,0) PATRIMONIO,
			ISNULL(PAT.PATRIMONIO_ORIGINAL,0) PATRIMONIO_ORIGINAL

		FROM ST_CORRETAGEM_ORDEM CO
		LEFT OUTER JOIN #PATRIMONIO_NET PAT
			ON CO.CD_CLIENTE = PAT.CD_CLIENTE
		WHERE 
			DT_NEGOCIO >= @dt_ini
		AND DT_NEGOCIO < @dt_fim
		GROUP BY CO.CD_CLIENTE, ISNULL(PAT.PATRIMONIO,0),ISNULL(PAT.PATRIMONIO_ORIGINAL,0)
	)X
	
	GROUP BY X.[DATA], X.CD_CLIENTE,ISNULL(X.PATRIMONIO,0),ISNULL(X.PATRIMONIO_ORIGINAL,0)
	HAVING  SUM(COMPRA) - SUM(VENDA) > abs(ISNULL(X.PATRIMONIO,0)) ----> REGRA DO ALERTA


--NETTING BMF
drop table if exists #BMF_NET
	SELECT 
		CAST(@PREGAO - @AUX AS DATE) AS [DATA],
		X.CD_CLIENTE,
		ABS(SUM(X.COMPRA) + SUM(X.VENDA)) AS VOLUME_BMF,
		ISNULL(X.PATRIMONIO,0) PATRIMONIO,
		ISNULL(X.PATRIMONIO_ORIGINAL,0) PATRIMONIO_ORIGINAL
	
	INTO #BMF_NET
	FROM(
		SELECT 
			DT_NEGOCIO AS [DATA],
			NC.CD_CLIENTE,
			SUM(CASE WHEN NC.CD_NATOPE = 'C' THEN (VL_VALOPE) ELSE 0 END) AS COMPRA,
			SUM(CASE WHEN NC.CD_NATOPE = 'V' THEN (VL_VALOPE) ELSE 0 END) AS VENDA,
			ISNULL(PAT.PATRIMONIO,0) PATRIMONIO,
			ISNULL(PAT.PATRIMONIO_ORIGINAL,0) PATRIMONIO_ORIGINAL

		FROM ST_BMF_NEGOCIOS_NC NC
		LEFT OUTER JOIN #PATRIMONIO_NET PAT
			ON NC.CD_CLIENTE = PAT.CD_CLIENTE
		WHERE 
			DT_NEGOCIO >= @dt_ini
		AND DT_NEGOCIO < @dt_fim
		AND NC.TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')	
		GROUP BY DT_NEGOCIO,NC.CD_CLIENTE, ISNULL(PAT.PATRIMONIO,0),ISNULL(PAT.PATRIMONIO_ORIGINAL,0) 
	)X
	

	GROUP BY 
		X.CD_CLIENTE,
		ISNULL(X.PATRIMONIO,0),
		ISNULL(X.PATRIMONIO_ORIGINAL,0) 
	HAVING  ABS(SUM(COMPRA) + SUM(VENDA)) > abs(ISNULL(X.PATRIMONIO,0))


--delete em caso de reprocessamento.
	DELETE FROM ST_ALERT_PATRIMONIO_NETTING WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          

------insert do alerta final            
	INSERT INTO ST_ALERT_PATRIMONIO_NETTING (DATA,CD_CLIENTE,NETTING_BVSP,NETTING_BMF,PATRIMONIO)
	SELECT DISTINCT 
		DATA, 
		CD_CLIENTE, 
		sum(VOLUME_BVSP)VOLUME_BVSP, 
		sum(VOLUME_BMF)VOLUME_BMF, 
		PATRIMONIO_ORIGINAL AS PATRIMONIO
	FROM (
		SELECT DATA, CD_CLIENTE, VOLUME_BVSP, 0 AS VOLUME_BMF, PATRIMONIO_ORIGINAL FROM #BOVESPA_NET
		UNION ALL
		SELECT DATA, CD_CLIENTE, 0 AS VOLUME_BVSP,VOLUME_BMF , PATRIMONIO_ORIGINAL FROM #BMF_NET
	)X
 group by
 DATA,CD_CLIENTE,PATRIMONIO_ORIGINAL
   
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_PATRIMONIO_NETTING', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_PATRIMONIO_NETTING
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_PATRIMONIO_NETTING_PADRAO