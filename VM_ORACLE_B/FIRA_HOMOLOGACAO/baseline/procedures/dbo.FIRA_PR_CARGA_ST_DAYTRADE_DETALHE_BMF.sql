CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_DAYTRADE_DETALHE_BMF] @PREGAO DATETIME, @PREGAOFIM DATETIME

AS

DROP TABLE IF EXISTS [dbo].[ST_DAYTRADE_DETALHE_BMF_PADRAO]
    CREATE TABLE [dbo].[ST_DAYTRADE_DETALHE_BMF_PADRAO] (
    [CD_CLIENTE] int NOT NULL,
    [QT_QTDDET] float NULL,
    [PR_NEGOCIO] float NULL,
    [VL_VALOPE] float NULL,
    [DT_DATMOV] datetime NULL,
    [CD_COMMOD] char(3) NULL,
    [CD_SERIE] char(4) NULL,
    [NR_NEGOCIO] numeric(12,0) NULL,
    [CD_NATOPE] varchar(1) NULL,
    [CD_CLIENTE_COMPROU_DE] int NULL,
    [CD_CONTRAPARTE_COMPROU] int NULL,
	[DT_FIRA] DATETIME NULL
);

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_DAYTRADE_DETALHE_BMF_PADRAO',
  @schema_name='dbo', @base_table='ST_DAYTRADE_DETALHE_BMF',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

--DECLARE @PREGAO DATETIME, @PREGAOFIM DATETIME
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260213'

/*******************************	
	CARGA ST_DAYTRADE_DETALHE_BMF		
********************************/  
   
WHILE @PREGAO < @PREGAOFIM 	
BEGIN	

	----
	--DELETA		
	DELETE ST_DAYTRADE_DETALHE_BMF WHERE DT_DATMOV = @PREGAO	
 	
	 
		----
		--INSERT FINAL		
		INSERT INTO ST_DAYTRADE_DETALHE_BMF	
		(
		CD_CLIENTE,QT_QTDDET,PR_NEGOCIO,VL_VALOPE,DT_DATMOV,CD_COMMOD,CD_SERIE,NR_NEGOCIO
		,CD_NATOPE,CD_CLIENTE_COMPROU_DE
		)
		SELECT DISTINCT 	
			D.CD_CLIENTE,	
			D.QT_QTDDET,	
			D.PR_NEGOCIO,	
			D.VL_VALOPE,	
			D.DT_DATMOV,	
			D.CD_COMMOD,	
			D.CD_SERIE,	
			D.NR_NEGOCIO,	
			D.CD_NATOPE,	
			E.CD_CLIENTE  AS CD_CLIENTE_COMPROU_DE
		FROM	
			(SELECT 
				CD_CLIENTE, 
				QT_QTDDET, 
				PR_NEGOCIO, 
				VL_VALOPE,
				CD_COMMOD, 
				CD_SERIE,
				NR_NEGOCIO, 
				CD_NATOPE, 
				DT_DATMOV	
			 FROM ST_BMF_NEGOCIOS_NC (NOLOCK) 
			 WHERE 
				 CD_NATOPE  = 'C' 
			 AND TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
			 AND DT_DATMOV  = @PREGAO ) AS D,			
		
			(SELECT 
				A.CD_CLIENTE, 
				A.QT_QTDDET, 
				A.PR_NEGOCIO, 
				A.VL_VALOPE,
				A.CD_COMMOD, 
				A.CD_SERIE,
				A.NR_NEGOCIO, 
				A.CD_NATOPE,  
				A.DT_DATMOV	
			 FROM ST_BMF_NEGOCIOS_NC (NOLOCK) A 
			 WHERE 
				 A.CD_NATOPE  = 'V' 
			 AND A.TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
			 AND A.DT_DATMOV  = @PREGAO ) AS E
		
		WHERE 
			D.CD_SERIE 	= E.CD_SERIE  	
		AND D.CD_COMMOD = E.CD_COMMOD 	
		AND D.NR_NEGOCIO = E.NR_NEGOCIO 	
		AND D.DT_DATMOV = E.DT_DATMOV 		
		
		
		UNION ALL	
		
		SELECT DISTINCT 
			D.CD_CLIENTE, 
			D.QT_QTDDET,	
			D.PR_NEGOCIO,	
			D.VL_VALOPE,	
			D.DT_DATMOV,	
			D.CD_COMMOD,	
			D.CD_SERIE,	
			D.NR_NEGOCIO,	
			D.CD_NATOPE,	
			E.CD_CLIENTE  AS CD_CLIENTE_COMPROU_DE
		FROM	
			(SELECT 
				CD_CLIENTE, 
				QT_QTDDET, 
				PR_NEGOCIO, 
				VL_VALOPE,
				CD_COMMOD, 
				CD_SERIE,
				NR_NEGOCIO, 
				CD_NATOPE, 
				DT_DATMOV 	
			FROM ST_BMF_NEGOCIOS_NC (NOLOCK)
			WHERE 
				CD_NATOPE  = 'V' 
			AND TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
			AND DT_DATMOV  = @PREGAO) AS D, -- TABELA
				
			(SELECT 
				A.CD_CLIENTE, 
				A.QT_QTDDET, 
				A.PR_NEGOCIO, 
				A.VL_VALOPE,
				A.CD_COMMOD, 
				A.CD_SERIE,
				A.NR_NEGOCIO, 
				A.CD_NATOPE,  
				A.DT_DATMOV	
			 FROM ST_BMF_NEGOCIOS_NC (NOLOCK) A 
			 WHERE 
				A.CD_NATOPE = 'C' 
			 AND A.TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')	
			 AND A.DT_DATMOV = @PREGAO) AS E
		WHERE 
			D.CD_SERIE = E.CD_SERIE  	
		AND D.CD_COMMOD = E.CD_COMMOD 		
		AND D.NR_NEGOCIO = E.NR_NEGOCIO 	
		AND D.DT_DATMOV = E.DT_DATMOV	
		
		
		UNION ALL	
		
		SELECT DISTINCT 
			D.CD_CLIENTE, 
			D.QT_QTDDET,	
			D.PR_NEGOCIO,	
			D.VL_VALOPE,	
			D.DT_DATMOV,	
			D.CD_COMMOD,	
			D.CD_SERIE,	
			D.NR_NEGOCIO,		
			D.CD_NATOPE,	
			NULL AS CD_CLIENTE_COMPROU_DE
		FROM	
		(SELECT 
			CD_CLIENTE, 
			QT_QTDDET, 
			PR_NEGOCIO, 
			VL_VALOPE,
			CD_COMMOD, 
			CD_SERIE,
			NR_NEGOCIO, 
			CD_NATOPE, 
			DT_DATMOV	
		 FROM ST_BMF_NEGOCIOS_NC (NOLOCK)
		 WHERE 
			CD_NATOPE = 'C' 
		 AND TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
		 AND DT_DATMOV = @PREGAO) AS D
	
		WHERE 
			NOT EXISTS( SELECT 
							E.NR_NEGOCIO, 
							E.DT_DATMOV, 
							E.CD_SERIE, 
							E.CD_COMMOD	
						FROM(
							SELECT A.CD_CLIENTE, A.QT_QTDDET, A.PR_NEGOCIO, A.VL_VALOPE ,A.CD_COMMOD, A.CD_SERIE,A.NR_NEGOCIO,
							A.CD_NATOPE,  A.DT_DATMOV	
							FROM ST_BMF_NEGOCIOS_NC (NOLOCK) A	
							WHERE 
								A.CD_NATOPE  = 'V' 
							AND A.TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
							AND A.DT_DATMOV  = @PREGAO
						) E	
						WHERE 
							E.CD_SERIE = D.CD_SERIE	
						AND E.CD_COMMOD = D.CD_COMMOD	
						AND E.DT_DATMOV= D.DT_DATMOV	
						AND E.NR_NEGOCIO = D.NR_NEGOCIO)	
		
		UNION ALL	
		
		SELECT DISTINCT 
			D.CD_CLIENTE, 
			D.QT_QTDDET,	
			D.PR_NEGOCIO,	
			D.VL_VALOPE,	
			D.DT_DATMOV,	
			D.CD_COMMOD,	
			D.CD_SERIE,	
			D.NR_NEGOCIO,	
			D.CD_NATOPE,	
			NULL AS CD_CLIENTE_COMPROU_DE
		FROM
		(SELECT 
			CD_CLIENTE, 
			QT_QTDDET, 
			PR_NEGOCIO, 
			VL_VALOPE,
			CD_COMMOD, 
			CD_SERIE,
			NR_NEGOCIO, 
			CD_NATOPE , 
			DT_DATMOV	
		 FROM ST_BMF_NEGOCIOS_NC (NOLOCK)
		 WHERE 
			CD_NATOPE   = 'V' 
		 AND TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')	
		 AND DT_DATMOV  = @PREGAO ) D	
	
		WHERE 
			NOT EXISTS( SELECT 
							E.NR_NEGOCIO, 
							E.DT_DATMOV, 
							E.CD_SERIE, 
							E.CD_COMMOD	
						FROM(	
							SELECT 
								A.CD_CLIENTE, A.QT_QTDDET, A.PR_NEGOCIO, 
								A.VL_VALOPE ,A.CD_COMMOD, A.CD_SERIE,
								A.NR_NEGOCIO, A.CD_NATOPE,  A.DT_DATMOV	
							FROM ST_BMF_NEGOCIOS_NC (NOLOCK) A	
							WHERE 
								A.CD_NATOPE  = 'C'  		
							AND A.TP_NEGOCIO IN ('DAY TRADE','DAYTRADE')
							AND A.DT_DATMOV  = @PREGAO 
							) E	
						WHERE E.CD_SERIE = D.CD_SERIE	
						AND E.CD_COMMOD = D.CD_COMMOD	
						AND E.DT_DATMOV= D.DT_DATMOV	
						AND E.NR_NEGOCIO = D.NR_NEGOCIO) 




	/***************
	 ### UPDATE ###
	***************/
 

		UPDATE ST_DAYTRADE_DETALHE_BMF
		SET CD_CONTRAPARTE_COMPROU = (SELECT MAX(CD_CORRET)
									  FROM ST_BMF_NEGOCIOS D (NOLOCK)
									  WHERE 
										  ST_DAYTRADE_DETALHE_BMF.DT_DATMOV = D.DT_NEGOCIO
									  AND ST_DAYTRADE_DETALHE_BMF.NR_NEGOCIO = D.NR_NEGOCIO)
		WHERE DT_DATMOV = @PREGAO

		
SET @PREGAO = @PREGAO +1	

END	

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_DAYTRADE_DETALHE_BMF', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_DAYTRADE_DETALHE_BMF
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END 


/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_DAYTRADE_DETALHE_BMF_PADRAO