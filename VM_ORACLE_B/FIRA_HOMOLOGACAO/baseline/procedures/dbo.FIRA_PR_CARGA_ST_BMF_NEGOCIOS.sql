CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_BMF_NEGOCIOS] @PREGAO DATETIME, @PREGAOFIM DATETIME
--WITH ENCRYPTION
AS

DROP TABLE IF EXISTS [dbo].[ST_BMF_NEGOCIOS_PADRAO]
    CREATE TABLE [dbo].[ST_BMF_NEGOCIOS_PADRAO] (
    [CD_CLIENTE] int NOT NULL,
    [DT_NEGOCIO] datetime NULL,
    [HR_NEGOCIO] varchar(8) NULL,
    [CD_COMMOD] varchar(10) NULL,
    [CD_SERIE] char(4) NULL,
    [CD_NEGOCIO] varchar(20) NULL,
    [CD_NATOPE] varchar(1) NULL,
    [VL_VOLUME] float NULL,
    [QT_NEGOCIO] float NOT NULL,
    [PR_NEGOCIO] float NOT NULL,
    [VALOR] float NULL,
    [TP_NEGOCIO] varchar(21) NULL,
    [NR_NEGOCIO] numeric(12,0) NULL,
    [IN_PESS_VINC] char(1) NULL,
    [CD_ASSESSOR] int NULL,
    [NM_ASSESSOR] varchar(60) NULL,
    [CD_CANAL] varchar(60) NULL,
    [CD_CORRET] int NULL,
    [CD_OPERADOR] varchar(10) NULL,
    [DT_DATORD] smalldatetime NULL,
    [NR_SEQORD] int NULL,
    [NR_SUBSEQ] int NULL,
    [DS_MERCAD] varchar(100) NULL,
    [NM_EMIT_ORDEM] varchar(100) NULL,
    [NM_USUARIO] varchar(100) NULL,
    [TP_CLIENTE] int NULL,
    [in_after] char(1) NULL,
	[DT_FIRA] DATETIME NULL
);

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_BMF_NEGOCIOS_PADRAO',
  @schema_name='dbo', @base_table='ST_BMF_NEGOCIOS',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;


/*******************************	
	CARGA ST_BMF_NEGOCIOS		
********************************/  

--DECLARE @PREGAO DATETIME, @PREGAOFIM DATETIME
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260214'

   
WHILE @PREGAO < @PREGAOFIM 	
BEGIN	

	----
	--DELETA		
	DELETE FROM ST_BMF_NEGOCIOS WHERE DT_NEGOCIO = @PREGAO 
 	
	----
	--INSERT FINAL		
		INSERT INTO ST_BMF_NEGOCIOS	
		(
		 CD_CLIENTE,DT_NEGOCIO,HR_NEGOCIO,CD_COMMOD,CD_SERIE,CD_NEGOCIO,CD_NATOPE,VL_VOLUME,QT_NEGOCIO
		,PR_NEGOCIO,VALOR,TP_NEGOCIO,NR_NEGOCIO,IN_PESS_VINC,CD_ASSESSOR,NM_ASSESSOR,CD_CANAL,CD_CORRET
		,CD_OPERADOR,DT_DATORD,NR_SEQORD,NR_SUBSEQ,DS_MERCAD,NM_EMIT_ORDEM,NM_USUARIO,TP_CLIENTE,in_after
		)
		SELECT 
			B.CD_CLIENTE,  	
			B.DT_NEGOCIO,  	
			A.HR_NEGOCIO,  	
			B.CD_COMMOD,  	
			B.CD_SERIE,	
			A.NR_NEGOCIO,  	
			B.CD_NATOPE,  	
			NULL,  	
			CAST(REPLACE(B.QT_QTDDET,',','.') AS FLOAT),  	
			CAST(RTRIM(LTRIM(REPLACE(B.PR_NEGOCIO,',','.')))AS FLOAT),  	
			CAST(REPLACE(B.VL_VALOPE,',','.') AS FLOAT),  	
			NULL,  	
			B.NR_NEGOCIO,  	
			A.IN_PESS_VINC,   	
			A.CD_ASSESSOR,  	
			A.NM_ASSESSOR,  	
			NULL CANAL,  	
			A.CD_CORRET,   	
			A.CD_OPERADOR,  	
			A.DT_DATORD,  	
			A.NR_SEQORD,  	
			A.NR_SUBSEQ,  	
			A.DS_MERCAD,  	
			A.NM_EMIT_ORDEM,  	
			A.NM_USUARIO, 
			A.TP_CLIENTE, 
			A.IN_AFTER	
		FROM ST_BMF_NEGOCIOS_NC B (NOLOCK)	
		LEFT OUTER JOIN (SELECT DISTINCT 
							NR_NEGOCIO, 
							CD_COMMOD, 
							CD_SERIE, 
							CD_NATOPE, 
							DT_PREGAO AS DT_NEGOCIO,
							HR_NEGOCIO,	
							IN_PESVIN AS IN_PESS_VINC,
							CODASS AS CD_ASSESSOR,
							NM_ASSESSOR,
							CD_CONTRAPAR AS CD_CORRET, 
							CD_OPERADOR, 
							DT_DATORD, 
							NR_SEQORD, 
							NR_SUBSEQ, 
							DS_MERCAD, 
							NM_EMIT_ORDEM, 
							NM_USUARIO,	
							TP_CLIENTE, 
							IN_AFTER 
						 FROM ST_BMF_NEGOCIOS_TMP1	(NOLOCK)
						 WHERE DT_PREGAO = @PREGAO ) A	
		
			ON  B.NR_NEGOCIO = A.NR_NEGOCIO	
			AND B.CD_COMMOD = A.CD_COMMOD	
			AND B.CD_SERIE = A.CD_SERIE	
			AND B.CD_NATOPE = A.CD_NATOPE	
			AND B.DT_NEGOCIO = A.DT_NEGOCIO		
		
		WHERE B.DT_NEGOCIO = @PREGAO
	
	
	--UPDATES	
		UPDATE ST_BMF_NEGOCIOS	
		SET CD_CORRET = (SELECT MAX(CD_CONTRAPARTE) 
						 FROM ST_BMF_NEGOCIOS_DET D	(NOLOCK)
						 WHERE 
							 ST_BMF_NEGOCIOS.DT_DATORD = D.DT_DATORD	
						 AND ST_BMF_NEGOCIOS.NR_SEQORD = D.NR_SEQORD	
						 )	
		WHERE DT_NEGOCIO = @PREGAO	
		
		
		UPDATE ST_BMF_NEGOCIOS_NC	
		SET CD_CONTRAPARTE = (SELECT MAX(CD_CORRET) 
							  FROM ST_BMF_NEGOCIOS D	(NOLOCK)
							  WHERE 
								  ST_BMF_NEGOCIOS_NC.DT_NEGOCIO = D.DT_NEGOCIO	
							  AND ST_BMF_NEGOCIOS_NC.NR_NEGOCIO = D.NR_NEGOCIO	
							 )	
		WHERE DT_NEGOCIO = @PREGAO	
		
			
		UPDATE ST_DAYTRADE_DETALHE_BMF	
		SET CD_CONTRAPARTE_COMPROU  = (SELECT MAX(CD_CONTRAPARTE) 
									   FROM ST_BMF_NEGOCIOS_NC D	(NOLOCK)
									   WHERE 
										   ST_DAYTRADE_DETALHE_BMF.DT_DATMOV = D.DT_NEGOCIO	
									   AND ST_DAYTRADE_DETALHE_BMF.NR_NEGOCIO = D.NR_NEGOCIO	
									  )	
		WHERE DT_DATMOV = @PREGAO	
	
		
SET @PREGAO = @PREGAO +1	
END	

	
/******* fim do processo de carga **********/

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_BMF_NEGOCIOS', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_BMF_NEGOCIOS]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_BMF_NEGOCIOS_PADRAO