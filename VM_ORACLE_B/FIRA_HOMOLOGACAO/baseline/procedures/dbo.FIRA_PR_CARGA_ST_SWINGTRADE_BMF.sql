CREATE   PROCEDURE [dbo].[FIRA_PR_CARGA_ST_SWINGTRADE_BMF] @PREGAO DATETIME, @PREGAOFIM DATETIME
--WITH ENCRYPTION
AS


DROP TABLE IF EXISTS [dbo].[ST_SWINGTRADE_BMF_PADRAO]
    CREATE TABLE [dbo].[ST_SWINGTRADE_BMF_PADRAO] (
    [PREGAO] smalldatetime NULL,
    [PREGAO_ANT] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_COMMOD] char(3) NULL,
    [CD_SERIE] char(4) NULL,
    [QUANTIDADE] float NULL,
    [PRECO_COMPRA] float NULL,
    [PRECO_VENDA] float NULL,
    [RESULTADO] float NULL,
    [QTD_SWINGTRADE] int NOT NULL,
    [FINANCEIRO] float NULL,
	[DT_FIRA] DATETIME NULL
);


/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_SWINGTRADE_BMF_PADRAO',
  @schema_name='dbo', @base_table='ST_SWINGTRADE_BMF',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

--DECLARE @PREGAO DATETIME , @PREGAOFIM DATETIME   
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260213'

/*******************************	
	CARGA ST_SWINGTRADE_BMF		
********************************/  
---
--VARIAVEIS PARA O CURSOR   
DECLARE @INICIO SMALLDATETIME, @FIM SMALLDATETIME, @PREGAO2 SMALLDATETIME, @PREGAO_ANT2 SMALLDATETIME     		
     		       		
SET @INICIO = @PREGAO     		      		
SET @FIM 	= @PREGAOFIM       		
        				
---
--DELETE
DELETE ST_SWINGTRADE_BMF WHERE PREGAO >= @INICIO      		
        		
   		   		
---
--CURSOR     		
DECLARE CONTAGEM CURSOR FOR    		
	SELECT 
		 DT_PERIODO_ANT
		,DT_PERIODO  		
	FROM ST_PERIODO (NOLOCK)		
	WHERE 
		DT_PERIODO >= @INICIO  		
	AND DT_PERIODO <= @FIM        		
        				
OPEN CONTAGEM        		
FETCH NEXT FROM CONTAGEM INTO @PREGAO_ANT2,@PREGAO2        		
WHILE @@FETCH_STATUS = 0        		      		
BEGIN        		
	
	---	
	--#PREGAO_ANT
	SELECT 
		F1.CD_CLIENTE AS CD_CLIENTE_COMPRA,  
		F1.CD_COMMOD, 
		ISNULL(F1.CD_SERIE,'') AS CD_SERIE, 		
		SUM(F1.QT_QTDDET) AS QUANTIDADE, 		
		cast(SUM(F1.VL_VALOPE) as decimal(20,2))  AS VALOR, 
		cast(SUM(F1.VL_VALOPE)/SUM(F1.QT_QTDDET) as decimal(20,2)) AS PRECO_COMPRA
		
	INTO #PREGAO_ANT		
	FROM ST_BMF_NEGOCIOS_NC (NOLOCK) F1		
	WHERE 
		F1.CD_NATOPE = 'C' 		
	AND F1.DT_NEGOCIO = @PREGAO_ANT2		
	AND F1.TP_NEGOCIO = 'NORMAL'		
	GROUP BY F1.CD_CLIENTE, F1.CD_COMMOD, ISNULL(F1.CD_SERIE,'')		
	
	---	
	--#PREGAO	
	SELECT 
		F1.CD_CLIENTE AS CD_CLIENTE_VENDA, 
		F1.CD_COMMOD, 
		ISNULL(F1.CD_SERIE,'') AS CD_SERIE, 		
		SUM(F1.QT_QTDDET) AS QUANTIDADE, 		
		cast(SUM(F1.VL_VALOPE) as decimal(20,2)) AS VALOR,		
		cast(SUM(F1.VL_VALOPE)/SUM(F1.QT_QTDDET) as decimal(20,2)) AS PRECO_VENDA 
		
	INTO #PREGAO		
	FROM ST_BMF_NEGOCIOS_NC  (NOLOCK) F1				
	WHERE 
		F1.CD_NATOPE = 'V' 		
	AND F1.DT_NEGOCIO = @PREGAO2		
	AND F1.TP_NEGOCIO = 'NORMAL'		
	GROUP BY F1.CD_CLIENTE, F1.CD_COMMOD, ISNULL(F1.CD_SERIE,'')		
			
			
			
	----
	--INSERT FINAL		
	INSERT INTO ST_SWINGTRADE_BMF
	(
	 PREGAO,PREGAO_ANT,CD_CLIENTE,CD_COMMOD,CD_SERIE,QUANTIDADE
	,PRECO_COMPRA,PRECO_VENDA,RESULTADO,QTD_SWINGTRADE,FINANCEIRO
	)
	SELECT 
		@PREGAO2, 
		@PREGAO_ANT2,
		P.CD_CLIENTE_VENDA AS CD_CLIENTE_PONTA, 
		P.CD_COMMOD,
		ISNULL(P.CD_SERIE,'') AS CD_SERIE,
		
		CASE 
			WHEN P.QUANTIDADE > PA.QUANTIDADE 
				THEN PA.QUANTIDADE 
			ELSE P.QUANTIDADE 
		END AS QUANTIDADE,	
		
		PA.PRECO_COMPRA, 
		P.PRECO_VENDA,	
		
		CASE 
			WHEN P.QUANTIDADE > PA.QUANTIDADE 
				THEN PA.QUANTIDADE 
			ELSE P.QUANTIDADE 
		END * (P.PRECO_VENDA + PA.PRECO_COMPRA) AS RESULTADO,
		
		1,		
		(P.VALOR - PA.VALOR) AS FINAN
		
	FROM #PREGAO P 
	INNER JOIN #PREGAO_ANT PA		
		ON  P.CD_COMMOD = PA.CD_COMMOD		
		AND ISNULL(P.CD_SERIE,'') = ISNULL(PA.CD_SERIE,'')		
		AND P.CD_CLIENTE_VENDA = PA.CD_CLIENTE_COMPRA		
	
		
	----
	--DROP TEMP		
	DROP TABLE #PREGAO      		
	DROP TABLE #PREGAO_ANT   		
		
   		
        		
--LENDO A PROXIMA LINHA        		     		
FETCH NEXT FROM CONTAGEM INTO @PREGAO_ANT2, @PREGAO2        		
        		
END        		   		
CLOSE CONTAGEM        		      		
DEALLOCATE CONTAGEM

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
	DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_SWINGTRADE_BMF', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_SWINGTRADE_BMF]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_SWINGTRADE_BMF_PADRAO