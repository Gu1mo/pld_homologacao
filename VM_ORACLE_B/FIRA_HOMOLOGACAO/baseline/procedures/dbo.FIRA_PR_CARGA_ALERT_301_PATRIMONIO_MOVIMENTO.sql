CREATE   PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_PATRIMONIO_MOVIMENTO] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS

/*************************************************************************************************
REGRA DO ALERTA:
Clientes que tiveram a soma dos valores de depósito maior que o patrimônio declarado absoluto
no ultimo dia util do mes.
*************************************************************************************************/

/*************************************************************************************************
Observação:
esse alerta utiliza os codigos historicos referente a DEPOSITO configurados na tabela de parametros
ST_CLIENTE_PARAMETROS
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_PATRIMONIO_MOVIMENTO_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_PATRIMONIO_MOVIMENTO_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NULL,
	[VOLUME_CC] [numeric](38, 2) NULL,
	[PATRIMONIO] [float] NOT NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabelaOK
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_PATRIMONIO_MOVIMENTO_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_PATRIMONIO_MOVIMENTO',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual
declare @dt_ini_6m date = dateadd(month, datediff(month,0, dateadd(month,-7,@pregao)),0) -- primeiro dia do 6 mes anterior ao mes atual
declare @dt_fim_6m date = @dt_ini -- 1 dia do mes atual
DECLARE @DT_REF DATE = DATEADD(DAY, - @AUX, @PREGAO);


drop table if exists #PATMOVCC
DECLARE @PERCENTUAL_ACRESCIMO NUMERIC(10,2) = (SELECT [CD_PARAMETRO] FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'PERCENTUAL_PATRIMONIO')
-- NULL = mantém o patrimônio original
-- 100  = acrescenta 100%
-- 50   = acrescenta 50%
-- 20   = acrescenta 20%

SELECT P.CD_CLIENTE
,P.PATRIMONIO_ORIGINAL
,CAST(P.PATRIMONIO_ORIGINAL * (1 + ISNULL(@PERCENTUAL_ACRESCIMO, 0) / 100.0) AS NUMERIC(38,2)) AS PATRIMONIO
INTO #PATMOVCC
FROM (SELECT XX.CD_CLIENTE
,XX.TIPO
,CAST(CASE WHEN XX.TIPO = 'PF' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_SITU_PATRM) WHEN XX.TIPO = 'PJ' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_PATRM_LIQ) ELSE SUM(XX.VAL_BENS) END AS NUMERIC(38,2)) AS PATRIMONIO_ORIGINAL
FROM ST_PATRIMONIO_LIQ XX
WHERE XX.DATA = (SELECT MAX(YY.DATA) FROM ST_PATRIMONIO_LIQ YY WHERE YY.DATA >= @DT_INI AND YY.DATA < @DT_FIM AND DATEPART(WEEKDAY, YY.DATA) NOT IN (1, 7))
GROUP BY XX.CD_CLIENTE
,XX.TIPO) P;


CREATE NONCLUSTERED INDEX T1 ON [DBO].[#PATMOVCC] ([CD_CLIENTE]) INCLUDE ([PATRIMONIO])      


--busco os depositos no mes do alerta
drop table if exists #FINALMOVCC
	SELECT
		A.DT_REFERENCIA,      
		A.CD_CLIENTE,
		A.CD_HISTORICO,         
             
		(SELECT ABS(CAST(SUM(VL_LANCAMENTO) AS NUMERIC(38,2))) 
		FROM ST_EXTRATO_CC XX      
		WHERE XX.CD_CLIENTE = A.CD_CLIENTE            
		AND XX.DT_REFERENCIA = A.DT_REFERENCIA   
		AND XX.CD_HISTORICO  IN (select CD_PARAMETRO From ST_CLIENTE_PARAMETROS where DS_PARAMETRO = 'DEPOSITO')) AS VL_LANCAMENTO, --SO DEPOSITO         
             
		ISNULL(PATRIMONIO_ORIGINAL,0) PATRIMONIO, 
             
		CASE 
			WHEN A.CD_HISTORICO NOT IN (select CD_PARAMETRO From ST_CLIENTE_PARAMETROS where DS_PARAMETRO = 'DEPOSITO')   THEN '' --DEPÓSITO           
			WHEN (SELECT ABS(CAST(SUM(VL_LANCAMENTO) AS NUMERIC(38,2))) 
				  FROM ST_EXTRATO_CC XX     
				  WHERE XX.CD_CLIENTE = A.CD_CLIENTE            
				  AND DT_REFERENCIA >= @dt_ini     
				  AND DT_REFERENCIA < @dt_fim  
				  AND XX.CD_HISTORICO  IN (select CD_PARAMETRO From ST_CLIENTE_PARAMETROS where DS_PARAMETRO = 'DEPOSITO')) > abs(ISNULL(PATRIMONIO,0)) THEN 'SIM' ELSE 'NÃO' END AS ALERTA ----> REGRA DO ALERTA
			  
	INTO #FINALMOVCC     
	FROM ST_EXTRATO_CC A          
	LEFT OUTER JOIN #PATMOVCC B 
		ON A.CD_CLIENTE = B.CD_CLIENTE          
	WHERE 
		DT_REFERENCIA >= @dt_ini     
	AND DT_REFERENCIA < @dt_fim 
	AND A.CD_HISTORICO IN (select CD_PARAMETRO From ST_CLIENTE_PARAMETROS where DS_PARAMETRO in ('DEPOSITO','RETIRADA'))  --DEPÓSITO + RETIRADA
	GROUP BY  DT_REFERENCIA ,A.CD_CLIENTE,CD_HISTORICO,ISNULL(PATRIMONIO_ORIGINAL,0)  ,ISNULL(PATRIMONIO,0)            


	--- DELETE TABLE ST_ALERT_PATRIMONIO_MOVIMENTO
	DELETE FROM ST_ALERT_PATRIMONIO_MOVIMENTO WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          
             
	---INSERT TABLE ST_ALERT_PATRIMONIO_MOVIMENTO
	INSERT INTO ST_ALERT_PATRIMONIO_MOVIMENTO (DATA,CD_CLIENTE,VOLUME_CC,PATRIMONIO)    
	SELECT 
	CAST(@PREGAO-@AUX AS DATE)DATA,
	CD_CLIENTE,
	ABS(SUM(VL_LANCAMENTO)) VOLUME_CC,         
	ISNULL(PATRIMONIO,0) PATRIMONIO  
	FROM #FINALMOVCC   
	WHERE ALERTA = 'SIM' ----> REGRA DO ALERTA
	GROUP BY CD_CLIENTE, ISNULL(PATRIMONIO,0)            
             

/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo. ST_ALERT_PATRIMONIO_MOVIMENTO', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo]. ST_ALERT_PATRIMONIO_MOVIMENTO
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_PATRIMONIO_MOVIMENTO_PADRAO