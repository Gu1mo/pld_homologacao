CREATE   PROCEDURE [dbo].[FIRA_PR_CARGA_ST_RESUMO_DIRETAS_BMF] @PREGAO DATETIME, @PREGAOFIM DATETIME
--WITH ENCRYPTION
AS


 DROP TABLE IF EXISTS [dbo].[ST_RESUMO_DIRETAS_BMF_PADRAO]
    CREATE TABLE [dbo].[ST_RESUMO_DIRETAS_BMF_PADRAO] (
    [dt_negocio] smalldatetime NULL,
    [cd_cliente] int NOT NULL,
    [qtd_diretas] int NULL,
    [qtd_negocios] int NULL,
    [PERC_TOT] float NULL,
    [CD_CLIENTE_PONTA] int NULL,
    [QTD_DIRETAS_PONTA] int NULL,
    [PERC_PONTA] float NULL,
    [IN_DAYTRADE_CONTRAPARTE] char(3) NULL,
	[DT_FIRA] DATETIME NULL
);


/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_RESUMO_DIRETAS_BMF_PADRAO',
  @schema_name='dbo', @base_table='ST_RESUMO_DIRETAS_BMF',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;



--declare @PREGAO DATETIME , @PREGAOFIM DATETIME
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260213'

/*******************************	
	CARGA ST_RESUMO_DIRETAS_BMF		
********************************/  
   
WHILE @PREGAO < @PREGAOFIM 	
BEGIN	

	----
	--DELETA		
	DELETE ST_RESUMO_DIRETAS_BMF WHERE DT_NEGOCIO = @PREGAO	
 	
	
	-------------
	---TEMP T1---
	-------------
	 	
		SELECT  
			 B.CD_CLIENTE		
			,B.CD_CLIENTE_COMPROU_DE
			,B.DT_DATMOV		
			,B.CD_COMMOD		
			,B.CD_SERIE		
			,B.QT_QTDDET 

		INTO #T1_C
		FROM ST_DAYTRADE_DETALHE_BMF (NOLOCK) B		
		WHERE B.CD_NATOPE = 'C'
		AND B.DT_DATMOV = @PREGAO


		SELECT   
			 B.CD_CLIENTE		
			,B.CD_CLIENTE_COMPROU_DE
			,B.DT_DATMOV		
			,B.CD_COMMOD		
			,B.CD_SERIE		
			,B.QT_QTDDET
			
		INTO #T1_V
		FROM ST_DAYTRADE_DETALHE_BMF (NOLOCK) B		
		WHERE B.CD_NATOPE = 'V'
		AND B.DT_DATMOV = @PREGAO


		--FINAL #T1
		SELECT DISTINCT 
			DT_NEGOCIO, 
			CD_CLIENTE_COMPRA, 
			NR_NEGOCIO, 
			CD_CLIENTE_VENDA,		
			(SELECT TOP 1 QT_QTDDET 
			 FROM #T1_C B		
			 WHERE 
				 ST_DIRETAS_BMF.CD_CLIENTE_COMPRA = B.CD_CLIENTE		
			 AND ST_DIRETAS_BMF.CD_CLIENTE_VENDA  = B.CD_CLIENTE_COMPROU_DE		
			 AND ST_DIRETAS_BMF.DT_NEGOCIO		  = B.DT_DATMOV		
			 AND ST_DIRETAS_BMF.CD_COMMOD		  = B.CD_COMMOD		
			 AND ST_DIRETAS_BMF.CD_SERIE		  = B.CD_SERIE ) AS DAYTRADE		
	
		INTO #T1		
		FROM ST_DIRETAS_BMF	(NOLOCK)	
		WHERE 
			CD_CLIENTE_COMPRA <> CD_CLIENTE_VENDA		
		AND DT_NEGOCIO = @PREGAO
	
		UNION ALL	
	
		SELECT DISTINCT 
			DT_NEGOCIO, 
			CD_CLIENTE_VENDA, 
			NR_NEGOCIO, 
			CD_CLIENTE_COMPRA,		
			(SELECT TOP 1 QT_QTDDET 
			 FROM #T1_V B		
			 WHERE ST_DIRETAS_BMF.CD_CLIENTE_VENDA = B.CD_CLIENTE		
			 AND ST_DIRETAS_BMF.CD_CLIENTE_COMPRA  = B.CD_CLIENTE_COMPROU_DE		
			 AND ST_DIRETAS_BMF.DT_NEGOCIO		   = B.DT_DATMOV		
			 AND ST_DIRETAS_BMF.CD_COMMOD		   = B.CD_COMMOD		
			 AND ST_DIRETAS_BMF.CD_SERIE		   = B.CD_SERIE ) AS DAYTRADE
	 
		FROM ST_DIRETAS_BMF	(NOLOCK)	
		WHERE 
			CD_CLIENTE_VENDA <> CD_CLIENTE_COMPRA		
		AND DT_NEGOCIO = @PREGAO

	 
		

	-------------
	---TEMP T2---
	-------------
	 
		SELECT 
			DT_NEGOCIO, 
			CD_CLIENTE_COMPRA,
			COUNT(DISTINCT NR_NEGOCIO) QTD, 
			CD_CLIENTE_VENDA, 
			SUM(DAYTRADE) DAYTRADE 
	
		INTO #T2		
		FROM #T1		
		GROUP BY DT_NEGOCIO, CD_CLIENTE_COMPRA, CD_CLIENTE_VENDA	

	 

	-------------
	---TEMP T3---
	-------------
	 
		SELECT 
			DT_NEGOCIO, 
			CD_CLIENTE_COMPRA, 
			SUM(QTD) QTD 
		
		INTO #T3		
		FROM #T2		
		GROUP BY DT_NEGOCIO, CD_CLIENTE_COMPRA	

	 


	-------------
	---TEMP T4---
	-------------
 
		SELECT 
			DT_NEGOCIO, 
			CD_CLIENTE, 
			DS_MERCAD,
			CD_COMMOD,
			CD_SERIE,
			COUNT(DISTINCT NR_NEGOCIO) QTD 
	
		INTO #T4		
		FROM ST_BMF_NEGOCIOS (NOLOCK) F	
		WHERE F.DT_NEGOCIO = @PREGAO		
		GROUP BY DT_NEGOCIO, CD_CLIENTE, DS_MERCAD,CD_COMMOD,CD_SERIE		
	
 

	-------------
	---TEMP T5---
	-------------	
	 
		SELECT 
			DT_NEGOCIO, 
			CD_CLIENTE,
			SUM(QTD) QTD  
		
		INTO #T5		
		FROM #T4		
		GROUP BY DT_NEGOCIO, CD_CLIENTE	

	 


	------------------
	---INSERT FINAL---
	------------------
	 
	INSERT INTO ST_RESUMO_DIRETAS_BMF	
	(
	 DT_NEGOCIO,CD_CLIENTE,QTD_DIRETAS,QTD_NEGOCIOS,PERC_TOT
	,CD_CLIENTE_PONTA,QTD_DIRETAS_PONTA,PERC_PONTA,IN_DAYTRADE_CONTRAPARTE
	)
	SELECT DISTINCT 
		A.DT_NEGOCIO, 
		A.CD_CLIENTE_COMPRA AS CD_CLIENTE,
		A.QTD AS QTD_DIRETAS,		
		B.QTD AS QTD_NEGOCIOS, 
		(CAST(A.QTD AS FLOAT) / CAST(B.QTD AS FLOAT) ) *100,		
		C.CD_CLIENTE_VENDA,
		C.QTD, 
		(CAST(C.QTD AS FLOAT) / CAST(A.QTD AS FLOAT)) * 100,		
		CASE WHEN C.DAYTRADE > 0 THEN 'SIM' ELSE 'NÃO' END AS DAYTRADE
		
	FROM #T3 A, 		
		 #T5 B, 		
		 #T2 C			
	WHERE 		
		A.DT_NEGOCIO = B.DT_NEGOCIO		
	AND A.CD_CLIENTE_COMPRA = B.CD_CLIENTE		
	AND A.DT_NEGOCIO = C.DT_NEGOCIO		
	AND A.CD_CLIENTE_COMPRA = C.CD_CLIENTE_COMPRA		
	
 

	----
	--DROP TEMP
	DROP TABLE #T1_C
	DROP TABLE #T1_V
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
IF COL_LENGTH(N'dbo.ST_RESUMO_DIRETAS_BMF', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_RESUMO_DIRETAS_BMF]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_RESUMO_DIRETAS_BMF_PADRAO