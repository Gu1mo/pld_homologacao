CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_TRANSFERENCIA_FINANCEIRA_02] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS


/*************************************************************************************************
REGRA DO ALERTA:
Clientes que fizeram depósitos e retiraram sem fazer nenhuma 
negociação no (período analisado: 30 dias).
*************************************************************************************************/


 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_TRANSFERENCIA_FINANCEIRA_02_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_TRANSFERENCIA_FINANCEIRA_02_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[TP_CLIENTE] [varchar](2) NULL,
	[NM_CLIENTE] [varchar](400) NULL,
	[CD_CPFCGC] [varchar](20) NULL,
	[DT_CRIACAO] [datetime2](7) NULL,
	[DT_DEPOSITO] [smalldatetime] NULL,
	[DT_RETIRADA] [smalldatetime] NULL,
	[TOTAL] [float] NULL,
	[PATRIMONIO] [float] NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_TRANSFERENCIA_FINANCEIRA_02_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_TRANSFERENCIA_FINANCEIRA_02',
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

	
 

--patrimonio do ultimo mes do alerta
drop table if exists #PATCUST
SELECT XX.CD_CLIENTE, isnull(CAST(SUM(VAL_BENS) AS NUMERIC(38,2)),0) PATRIMONIO
INTO #PATCUST
FROM ST_PATRIMONIO_LIQ  XX
WHERE DATA = (SELECT MAX(DATA) FROM ST_PATRIMONIO_LIQ YY 
				WHERE DATA >= @dt_ini
				AND DATA < @dt_fim
				and DATEPART(WEEKDAY, DATA) NOT IN (7,1)
			  )
 GROUP BY  XX.CD_CLIENTE
 
CREATE NONCLUSTERED INDEX T1         
ON [DBO].[#PATCUST] ([CD_CLIENTE]) 
INCLUDE ([PATRIMONIO])    



	
--DEPOSITO
drop table if exists #DEPOSITO
	SELECT CD_CLIENTE
		 , MAX(DT_REFERENCIA)DT_DEPOSITO
		 , CD_HISTORICO
		 , 'DEPOSITOS' AS DESCRICAO
	     , SUM(CAST(VL_LANCAMENTO AS FLOAT))TOTAL
	INTO #DEPOSITO
	FROM ST_EXTRATO_CC
	WHERE DT_REFERENCIA >= @dt_ini     
	  AND DT_REFERENCIA < @dt_fim     
	  AND CD_HISTORICO IN (SELECT CD_PARAMETRO FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'DEPOSITO') 
 GROUP BY CD_CLIENTE
		 ,CD_HISTORICO
		 
             
--RETIRADA
drop table if exists #RETIRADA
	SELECT CD_CLIENTE
		 , MAX(DT_REFERENCIA)DT_RETIRADA
		 , CD_HISTORICO
		 , 'RETIRADA' as DESCRICAO
		 , SUM(CAST(VL_LANCAMENTO AS FLOAT)) TOTAL
	INTO #RETIRADA
	FROM ST_EXTRATO_CC
   WHERE DT_REFERENCIA >= @dt_ini     
	  AND DT_REFERENCIA < @dt_fim     
	 AND CD_HISTORICO IN (SELECT CD_PARAMETRO FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'RETIRADA')
	GROUP BY CD_CLIENTE
		    ,CD_HISTORICO
				

--NEGOCIACAO
drop table if exists #NEGOCIACAO
	SELECT CD_CLIENTE
		 , MAX(DT_REFERENCIA) DT_DEPOSITO
		 , CD_HISTORICO
		 , 'NEGOCIACAO' as DESCRICAO
		, SUM(CAST(VL_LANCAMENTO AS FLOAT))TOTAL
	INTO #NEGOCIACAO
	FROM ST_EXTRATO_CC
	WHERE DT_REFERENCIA >= @dt_ini     
	  AND DT_REFERENCIA < @dt_fim     
	  AND CD_HISTORICO NOT IN (SELECT CD_PARAMETRO FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO IN('RETIRADA','DEPOSITO'))
 GROUP BY CD_CLIENTE
		 ,CD_HISTORICO
 
 --pedo somente o que preciso dos dados basicos
 drop table if exists #v_Cliente_todos
 select distinct 'PF' as TP_CLIENTE, CD_CLIENTE, NM_CLIENTE, CD_CPFCGC, DT_CRIACAO 
 into #v_Cliente_todos
 from ST_DADOS_BASICOS_PF
 union all
 select distinct 'PJ' as TP_CLIENTE, CD_CLIENTE, NM_CLIENTE, CD_CPFCGC, DT_CRIACAO 
 from ST_DADOS_BASICOS_PJ			  
			  
		

--FINAL       
	DELETE FROM ST_ALERT_TRANSFERENCIA_FINANCEIRA_02 WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          
	             
	INSERT INTO  ST_ALERT_TRANSFERENCIA_FINANCEIRA_02 (DATA,CD_CLIENTE,TP_CLIENTE,NM_CLIENTE,CD_CPFCGC,DT_CRIACAO,DT_DEPOSITO,DT_RETIRADA,TOTAL,PATRIMONIO)
		 SELECT CAST(@PREGAO-@AUX AS DATE) DATA
			  , A.CD_CLIENTE
			  , F.TP_CLIENTE             
			  , F.NM_CLIENTE
			  , F.CD_CPFCGC
			  , F.DT_CRIACAO
			  , A.DT_DEPOSITO
			  , B.DT_RETIRADA
			  , B.TOTAL
			  , ISNULL(PAT.PATRIMONIO,0) AS PATRIMONIO
		   FROM #DEPOSITO A
LEFT OUTER JOIN  #RETIRADA B 
			 ON A.CD_CLIENTE = B.CD_CLIENTE 
			AND A.DT_DEPOSITO < B.DT_RETIRADA 
LEFT OUTER JOIN #V_CLIENTE_TODOS F 
			 ON A.CD_CLIENTE = F.CD_CLIENTE	
LEFT OUTER JOIN #PATCUST PAT ON A.CD_CLIENTE = PAT.Cd_CLIENTE

		  WHERE NOT EXISTS (SELECT * FROM #NEGOCIACAO C WHERE C.CD_CLIENTE = A.CD_CLIENTE)
		    AND B.DT_RETIRADA IS NOT NULL         
            
  
/******* fim do processo de carga do alerta **********/

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_TRANSFERENCIA_FINANCEIRA_02', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_ALERT_TRANSFERENCIA_FINANCEIRA_02]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END
--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_TRANSFERENCIA_FINANCEIRA_02_PADRAO