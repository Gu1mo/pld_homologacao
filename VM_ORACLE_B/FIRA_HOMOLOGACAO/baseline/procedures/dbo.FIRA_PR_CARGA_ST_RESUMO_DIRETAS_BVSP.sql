CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_RESUMO_DIRETAS_BVSP] @PREGAO DATETIME , @PREGAOFIM DATETIME
--WITH ENCRYPTION
AS


DROP TABLE IF EXISTS [dbo].[ST_RESUMO_DIRETAS_BVSP_PADRAO]
    CREATE TABLE [dbo].[ST_RESUMO_DIRETAS_BVSP_PADRAO] (
    [DT_PERIODO] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [QTD_DIRETAS] int NULL,
    [QTD_NEGOCIOS] int NULL,
    [PERC_TOT] float NULL,
    [CD_CLIENTE_PONTA] int NOT NULL,
    [QTD_DIRETAS_PONTA] int NULL,
    [PERC_ponta] float NULL,
    [DAYTRADE] varchar(3) NOT NULL,
	[DT_FIRA] DATETIME NULL
); 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_RESUMO_DIRETAS_BVSP_PADRAO',
  @schema_name='dbo', @base_table='ST_RESUMO_DIRETAS_BVSP',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

--DECLARE @PREGAO DATETIME , @PREGAOFIM DATETIME   
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260213'


/****************************	
	CARGA ST_RESUMO_DIRETAS_BVSP		
****************************/     

WHILE @PREGAO < @PREGAOFIM 	
BEGIN	

	DELETE FROM ST_RESUMO_DIRETAS_BVSP	WHERE DT_PERIODO = @PREGAO	
	
	
	/*******************************
	  #### PRIMEIRO PROCESSO  ####
	*******************************/ 
	
	 
		
		SELECT DISTINCT 
			DT_PERIODO, 
			CD_CLIENTE_COMPRA, 
			NR_NEGOCIO, 
			CD_PAPEL,
			CD_CLIENTE_VENDA,
			
			(SELECT TOP 1 QT_DAYTRADE 
			 FROM ST_DAYTRADE_DETALHE B		
			 WHERE 
				 ST_DIRETAS_BVSP.CD_CLIENTE_COMPRA = B.CD_CLIENTE_COMPROU		
			 AND ST_DIRETAS_BVSP.CD_CLIENTE_VENDA = B.CD_CLIENTE_COMPROU_DE		
			 AND ST_DIRETAS_BVSP.DT_PERIODO = B.DT_PREGAO_COMPROU		
			 AND ST_DIRETAS_BVSP.CD_PAPEL = B.CD_NEGOCIO_COMPROU		
			 AND B.CD_NATOPE = 'C') AS DAYTRADE		
		
		INTO #T1		
		FROM ST_DIRETAS_BVSP		
		WHERE CD_CLIENTE_COMPRA <> CD_CLIENTE_VENDA		
		AND DT_PERIODO = @PREGAO		
	
		UNION ALL		
		
		SELECT DISTINCT 
			DT_PERIODO, 
			CD_CLIENTE_VENDA, 
			NR_NEGOCIO, 
			CD_PAPEL,
			CD_CLIENTE_COMPRA,		
			(SELECT TOP 1 QT_DAYTRADE 
			 FROM ST_DAYTRADE_DETALHE B		
			 WHERE ST_DIRETAS_BVSP.CD_CLIENTE_VENDA = B.CD_CLIENTE_COMPROU		
			 AND ST_DIRETAS_BVSP.CD_CLIENTE_COMPRA = B.CD_CLIENTE_COMPROU_DE		
			 AND ST_DIRETAS_BVSP.DT_PERIODO = B.DT_PREGAO_COMPROU		
			 AND ST_DIRETAS_BVSP.CD_PAPEL = B.CD_NEGOCIO_COMPROU		
			 AND B.CD_NATOPE = 'V') AS DAYTRADE	
		 
		FROM ST_DIRETAS_BVSP		
		WHERE CD_CLIENTE_VENDA <> CD_CLIENTE_COMPRA		
		AND DT_PERIODO = @PREGAO		
	
	
		SELECT 
			DT_PERIODO, 
			CD_CLIENTE_COMPRA,
			COUNT(DISTINCT NR_NEGOCIO) QTD, 
			CD_CLIENTE_VENDA, 
			SUM(DAYTRADE) DAYTRADE 
		INTO #T2		
		FROM #T1		
		GROUP BY DT_PERIODO, CD_CLIENTE_COMPRA, CD_CLIENTE_VENDA		
			
			
		SELECT 
			DT_PERIODO, 
			CD_CLIENTE_COMPRA,
			SUM(QTD) QTD 
		INTO #T3		
		FROM #T2		
		GROUP BY DT_PERIODO, CD_CLIENTE_COMPRA		


	 
	
	
	/*****************************
	  #### SEGUNDO PROCESSO  ####
	*****************************/
	
	 
		
		SELECT 
			DT_NEGOCIO DT_PERIODO, 
			CD_CLIENTE, 
			TP_MERCADO, 
			CD_PAPEL,
			COUNT(DISTINCT NR_NEGOCIO) QTD 
			
		INTO #T4		
		FROM ST_CORRETAGEM_ORDEM F		
		WHERE DT_NEGOCIO = @PREGAO		
		GROUP BY DT_NEGOCIO, CD_CLIENTE, TP_MERCADO, CD_PAPEL		
				
				
		SELECT 
			DT_PERIODO, 
			CD_CLIENTE, 
			SUM(QTD) QTD  
			
		INTO #T5		
		FROM #T4		
		GROUP BY DT_PERIODO, CD_CLIENTE		
	 
 
		 
		 
	/******************************
	  #### TERCEIRO PROCESSO  ####
	******************************/
	
	 
		INSERT INTO ST_RESUMO_DIRETAS_BVSP	
		(
		 DT_PERIODO,CD_CLIENTE,QTD_DIRETAS,QTD_NEGOCIOS
		,PERC_TOT,CD_CLIENTE_PONTA,QTD_DIRETAS_PONTA,PERC_ponta,DAYTRADE
		)
		SELECT 
			A.DT_PERIODO, 
			A.CD_CLIENTE_COMPRA AS CD_CLIENTE, 
			A.QTD AS QTD_DIRETAS,		
			B.QTD AS QTD_NEGOCIOS, 
			(CAST(A.QTD AS FLOAT) / CAST(B.QTD AS FLOAT) ) *100 AS PERC_TOT,		
			C.CD_CLIENTE_VENDA AS CD_CLIENTE_PONTA,
			C.QTD AS QTD_DIRETAS_PONTA, 
			(CAST(C.QTD AS FLOAT) / CAST(A.QTD AS FLOAT)) * 100 AS PERC_PONTA,		
			CASE WHEN C.DAYTRADE > 0 THEN 'SIM' ELSE 'NÃO' END AS DAYTRADE	
			
		FROM 
			#T3 A, 
			#T5 B, 
			#T2 C		
		WHERE 
			A.DT_PERIODO = B.DT_PERIODO		
		AND A.CD_CLIENTE_COMPRA = B.CD_CLIENTE		
		AND A.DT_PERIODO = C.DT_PERIODO		
		AND A.CD_CLIENTE_COMPRA = C.CD_CLIENTE_COMPRA		

	 


	/**********************
	  #### DROP TEMP  ####
	**********************/
	DROP TABLE #T1
	DROP TABLE #T2
	DROP TABLE #T3
	DROP TABLE #T4
	DROP TABLE #T5

SET @PREGAO = @PREGAO +1

END	

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
	DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_RESUMO_DIRETAS_BVSP', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_RESUMO_DIRETAS_BVSP]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_RESUMO_DIRETAS_BVSP_PADRAO