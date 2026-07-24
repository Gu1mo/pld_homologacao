CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_MANIPULACAO_BVSP] 
AS


  DROP TABLE IF EXISTS [dbo].[ST_MANIPULACAO_BVSP_PADRAO]
    CREATE TABLE [dbo].[ST_MANIPULACAO_BVSP_PADRAO] (
    [DT_PERIODO] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_CLIENTE_BRO] int NULL,
    [CD_PAPEL] varchar(12) NULL,
    [INDICE_BVSP] varchar(1) NOT NULL,
    [PREMED] numeric(17,2) NOT NULL,
    [PREABE] numeric(17,2) NOT NULL,
    [PREULT] numeric(17,2) NOT NULL,
    [VOLUME] float NULL,
    [VOLUME_CLIENTE_ANT] float NOT NULL,
    [VOL_MED_ATUAL] float NOT NULL,
    [VARIACAO_CLIENTE] float NOT NULL,
    [VARIACAO_CLIENTE_STRING] varchar(31) NULL,
    [VOLUME_MERCADO] float NULL,
    [VOLUME_MERCADO_ANT] float NOT NULL,
    [VARIACAO_MERCADO] float NOT NULL,
    [VARIACAO_MERCADO_STRING] varchar(31) NULL,
    [PERC_CLIENTE_MERCADO] float NOT NULL,
    [PERC_CLIENTE_MERCADO_STRING] varchar(31) NULL,
    [IND_LEILAO] varchar(1) NOT NULL,
    [VL_NEGOCIO_ABERTURA] float NOT NULL,
    [VL_NEGOCIO_FECHAMENTO] float NOT NULL,
    [VL_NEGOCIO_MIN] float NULL,
    [VL_NEGOCIO_MAX] float NULL,
    [VL_NEGOCIO_AVG] float NULL,
    [QTD_NEGOCIO] int NOT NULL,
    [PRECO_MIN_MERCADO] numeric(17,2) NOT NULL,
    [PRECO_MAX_MERCADO] numeric(17,2) NOT NULL,
    [QTD_NEGOCIOS_MERCADO] numeric(17,0) NOT NULL,
    [INTRADAY_CLIENTE] float NOT NULL,
    [INTRADAY_CLIENTE_STRING] varchar(31) NULL,
    [INTERDAY_CLIENTE] float NOT NULL,
    [INTERDAY_CLIENTE_STRING] varchar(31) NULL,
    [INTRADAY_MERCADO] numeric(38,20) NULL,
    [INTRADAY_MERCADO_STRING] varchar(31) NULL,
    [INTERDAY_MERCADO] numeric(38,20) NULL,
    [INTERDAY_MERCADO_STRING] varchar(31) NULL,
    [PRAZOT] varchar(20) NULL,
	[DT_FIRA] DATETIME NULL
);

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_MANIPULACAO_BVSP_PADRAO',
  @schema_name='dbo', @base_table='ST_MANIPULACAO_BVSP',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX01_ST_MANIPULACAO_BVSP' AND object_id = OBJECT_ID('dbo.ST_MANIPULACAO_BVSP'))
	BEGIN
		CREATE NONCLUSTERED INDEX IDX01_ST_MANIPULACAO_BVSP
		ON [dbo].[ST_MANIPULACAO_BVSP] ([DT_PERIODO])
	END

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX02_ST_MANIPULACAO_BVSP' AND object_id = OBJECT_ID('dbo.ST_MANIPULACAO_BVSP'))
	BEGIN
		CREATE NONCLUSTERED INDEX IDX02_ST_MANIPULACAO_BVSP
		ON [dbo].[ST_MANIPULACAO_BVSP] ([CD_CLIENTE],[CD_PAPEL])
	END

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX03_ST_MANIPULACAO_BVSP' AND object_id = OBJECT_ID('dbo.ST_MANIPULACAO_BVSP'))
	BEGIN		
		CREATE NONCLUSTERED INDEX IDX03_ST_MANIPULACAO_BVSP
		ON [dbo].[ST_MANIPULACAO_BVSP] ([DT_PERIODO])
		INCLUDE ([CD_CLIENTE],[CD_CLIENTE_BRO],[CD_PAPEL],[INDICE_BVSP],[PRAZOT],[PREMED],[PREABE],[PREULT],[VOLUME],[VOLUME_CLIENTE_ANT],[VOL_MED_ATUAL],[VARIACAO_CLIENTE],[VARIACAO_CLIENTE_STRING],[VOLUME_MERCADO],[VOLUME_MERCADO_ANT],[VARIACAO_MERCADO],[VARIACAO_MERCADO_STRING],[PERC_CLIENTE_MERCADO],[PERC_CLIENTE_MERCADO_STRING],[IND_LEILAO],[VL_NEGOCIO_ABERTURA],[VL_NEGOCIO_FECHAMENTO],[VL_NEGOCIO_MIN],[VL_NEGOCIO_MAX],[VL_NEGOCIO_AVG],[QTD_NEGOCIO],[PRECO_MIN_MERCADO],[PRECO_MAX_MERCADO],[QTD_NEGOCIOS_MERCADO],[INTRADAY_CLIENTE],[INTRADAY_CLIENTE_STRING],[INTERDAY_CLIENTE],[INTERDAY_CLIENTE_STRING],[INTRADAY_MERCADO],[INTRADAY_MERCADO_STRING],[INTERDAY_MERCADO],[INTERDAY_MERCADO_STRING])
	END
 

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx01_st_ativo_bovespa' AND object_id = OBJECT_ID('dbo.st_ativo_bovespa'))
	BEGIN
		IF EXISTS (SELECT * FROM sys.columns WHERE name IN ('DT_PERIODO', 'CODNEG', 'PREABE', 'PREMAX', 'PREMIN', 'PREMED', 'PREULT', 'QUATOT', 'VOLTOT') AND object_id = OBJECT_ID('dbo.st_ativo_bovespa'))
		BEGIN
		    CREATE NONCLUSTERED INDEX IDX01_ST_ATIVO_BOVESPA
		    ON dbo.st_ativo_bovespa (DT_PERIODO)
		    INCLUDE (CODNEG, PRAZOT, PREABE, PREMAX, PREMIN, PREMED, PREULT, QUATOT, VOLTOT);
		END
    END

  /*
	Verifica se existe as tabelas e index - FIM
  */
 
  ----------------------------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------------------------------

  /*
	Inicio da Carga
  */

  DECLARE @DT_PREGAO SMALLDATETIME,@DT_ATIVO_BOVESPA SMALLDATETIME,@CD_ANOMES INT,@DT_PREGAO_ANTERIOR SMALLDATETIME 
  
  /*
  Pegamos a maior data da tabela ST_ATIVO_BOVESPA que indicará até que dia podemos processar os dados da tabela
  */
  SET @DT_ATIVO_BOVESPA = (SELECT MAX(DT_PERIODO) FROM ST_ATIVO_BOVESPA) 
  
  /*
  Se a tabela ST_MANIPULACAO_BVSP estiver vazia, o processo irá coletar dados correspondentes aos últimos 6 meses para preenchê-la.
  Nuinvest demorou 35 minutos para carregar 6 meses.
  */
  SET @DT_PREGAO        = (SELECT MAX(DT_PERIODO) FROM ST_MANIPULACAO_BVSP) 
  

  IF @DT_PREGAO IS NULL
  BEGIN
	SET @DT_PREGAO = DATEADD(MONTH,-18,CAST(GETDATE() AS DATE))
	
	/*
	Para evitar que a variável @dt_pregao contenha uma data no meio do mês fazendo com que o mês fique incompleto, 
	fazemos o seguinte: primeiro, definimos a data de início dos 6 meses nessa variável. 
	Em seguida, usamos outra variável chamada cd_anomes para pegar o primeiro dia do mês correspondente, 
	garantindo que o mês completo seja considerado.
	*/

	SET @CD_ANOMES		= (SELECT MAX(CD_ANOMES) FROM ST_PERIODO WHERE DT_PERIODO = @DT_PREGAO)

	/*
	Ao definir a variável @dt_pregao usando a variável cd_anomes, asseguramos que estamos selecionando a data do primeiro dia do mês.
	*/
	SET @DT_PREGAO		= (SELECT MIN(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANOMES = @CD_ANOMES) 
  END


 /*
 While irá percorrer todas as datas entre @DT_PREGaO até @DT_ATIVO_BOVESPA, carregando na ST_MANIPULACAO_BVSP dia a dia.
 */
WHILE @DT_PREGAO <= @DT_ATIVO_BOVESPA
	
	BEGIN
		PRINT CONVERT(VARCHAR,@DT_PREGAO,23)
		----------------------------------------------------------------------------------------------------------------------
		  SET @DT_PREGAO_ANTERIOR = NULL
		  SET @DT_PREGAO_ANTERIOR = (SELECT DISTINCT MAX(DT_PERIODO) FROM ST_ATIVO_BOVESPA WHERE DT_PERIODO < @DT_PREGAO)

		  IF OBJECT_ID('tempdb..#ST_MANIPULACAO_BVSP_ANT') IS NOT NULL DROP TABLE #ST_MANIPULACAO_BVSP_ANT
		  SELECT * INTO #ST_MANIPULACAO_BVSP_ANT FROM ST_MANIPULACAO_BVSP WHERE DT_PERIODO = @DT_PREGAO_ANTERIOR;
		
		PRINT CONVERT(VARCHAR,@DT_PREGAO_ANTERIOR,23)		
		----------------------------------------------------------------------------------------------------------------------
		  IF OBJECT_ID('tempdb..#VOLUME_MERCADO_ATUAL') IS NOT NULL DROP TABLE #VOLUME_MERCADO_ATUAL 
		  SELECT DT_PERIODO
				,CODNEG
				,VOLTOT AS VOLUME_MERCADO
				,PRAZOT
				,cast(PREMIN as numeric(17,2) )PREMIN
				,cast(PREMAX as numeric(17,2) )PREMAX 
				,cast(QUATOT as numeric(38,2) )QUATOT 
				,cast(PREMED as numeric(17,2) )PREMED
				,cast(PREABE as numeric(17,2) )PREABE
				,cast(PREULT as numeric(17,2) )PREULT
			INTO #VOLUME_MERCADO_ATUAL
			FROM ST_ATIVO_BOVESPA A
		   WHERE A.DT_PERIODO = @DT_PREGAO;

		  
		  CREATE NONCLUSTERED INDEX ID01_VOLUME_MERCADO_ATUAL
			 ON [dbo].[#VOLUME_MERCADO_ATUAL] ([CODNEG])
			 INCLUDE ([DT_PERIODO],[VOLUME_MERCADO],[PRAZOT],[PREMIN],[PREMAX],[QUATOT],[PREMED],[PREABE],[PREULT])

	      ----------------------------------------------------------------------------------------------------------------------
		  IF OBJECT_ID('tempdb..#ST_CORRETAGEM_ORDEM2') IS NOT NULL DROP TABLE #ST_CORRETAGEM_ORDEM2
		  SELECT CD_CLIENTE
				, NR_SEQORD
				, DT_DATORD
				, HH_NEGOCIO
				, NR_NEGOCIO
				, DT_NEGOCIO
				, CD_PAPEL 
				, VL_NEGOCIO
				, VL_TOTNEG
				, QT_MULTIPLICADOR
				, CD_CLIENTE_BRO
				, IN_LEILAO
				, CAST(TP_VCOTER AS VARCHAR (5)) TP_VCOTER --TRANSFORMO EM VARCHAR
				INTO #ST_CORRETAGEM_ORDEM2
			 FROM ST_CORRETAGEM_ORDEM 
			WHERE DT_NEGOCIO = @DT_PREGAO;

			----------------------------------------------------------------------------------------------------------------------
			IF OBJECT_ID('tempdb..#ST_CORRETAGEM_ORDEM') IS NOT NULL DROP TABLE #ST_CORRETAGEM_ORDEM
			SELECT CD_CLIENTE
				, NR_SEQORD
				, DT_DATORD
				, HH_NEGOCIO
				, NR_NEGOCIO
				, DT_NEGOCIO
				, CD_PAPEL 
				, VL_NEGOCIO
				, VL_TOTNEG
				, QT_MULTIPLICADOR
				, CD_CLIENTE_BRO
				, IN_LEILAO
				, ISNULL(TP_VCOTER, '000') AS TP_VCOTER --TRANSFORMO ISNULL EM 000
				INTO #ST_CORRETAGEM_ORDEM
			 FROM #ST_CORRETAGEM_ORDEM2 
			WHERE DT_NEGOCIO = @DT_PREGAO;
		
	      ----------------------------------------------------------------------------------------------------------------------	
		  
			  CREATE NONCLUSTERED INDEX [IDX01]
			  ON [dbo].[#ST_CORRETAGEM_ORDEM] ([CD_CLIENTE],[NR_NEGOCIO],[DT_NEGOCIO],[CD_PAPEL])
			  INCLUDE ([VL_NEGOCIO]);
		
			  CREATE NONCLUSTERED INDEX [IDX02]
			  ON [dbo].[#ST_CORRETAGEM_ORDEM] ([CD_CLIENTE],[NR_NEGOCIO],[DT_NEGOCIO],[CD_PAPEL])
			  INCLUDE ([VL_NEGOCIO]);
		
			  CREATE NONCLUSTERED INDEX [IDX03]
			  ON [dbo].[#ST_CORRETAGEM_ORDEM] ([CD_CLIENTE],[CD_PAPEL])
			  INCLUDE ([NR_NEGOCIO],[DT_NEGOCIO],[VL_NEGOCIO]);

				-----------------------------------------------------------------------------------------
		   IF OBJECT_ID('tempdb..#VOLUME_CLIENTE_ATUAL') IS NOT NULL DROP TABLE #VOLUME_CLIENTE_ATUAL;
		   SELECT A.CD_CLIENTE
				, A.CD_CLIENTE_BRO
				, A.CD_PAPEL
				, A.DT_NEGOCIO AS DT_PERIODO
				, A.IN_LEILAO
				, ISNULL(SUM(A.VL_TOTNEG), 0) AS VOL_CLI_ATUAL
				, ISNULL(AVG(A.VL_TOTNEG), 0) AS VOL_MED_ATUAL

			INTO #VOLUME_CLIENTE_ATUAL
			FROM #ST_CORRETAGEM_ORDEM A
		GROUP BY A.CD_CLIENTE
				,A.CD_CLIENTE_BRO
				,A.CD_PAPEL
				,A.DT_NEGOCIO
				,A.IN_LEILAO;

			-----------------------------------------------------------------------------------------

		   IF OBJECT_ID('tempdb..#NEGOCIO_ABERTURA') IS NOT NULL DROP TABLE #NEGOCIO_ABERTURA;

					   SELECT CD_CLIENTE
							, DT_NEGOCIO
							, CD_PAPEL
							, MIN(NR_NEGOCIO) ABERTURA_NR_NEGOCIO
							, MAX(NR_NEGOCIO) FECHAMENTO_NR_NEGOCIO
							, MAX(VL_NEGOCIO) VL_NEGOCIO_MAX
							, MIN(VL_NEGOCIO) VL_NEGOCIO_MIN
							, AVG(VL_NEGOCIO) VL_NEGOCIO_AVG
							, COUNT(NR_NEGOCIO) QTD_NEGOCIO
						INTO #NEGOCIO_ABERTURA
						FROM #ST_CORRETAGEM_ORDEM
					GROUP BY  CD_CLIENTE
							, DT_NEGOCIO
							, CD_PAPEL
				
				-----------------------------------------------------------------------------------------		
				CREATE NONCLUSTERED INDEX [IDX_ABERTURA_01]
				ON [dbo].[#NEGOCIO_ABERTURA] ([CD_CLIENTE],[DT_NEGOCIO],[CD_PAPEL],[ABERTURA_NR_NEGOCIO])
				INCLUDE ([VL_NEGOCIO_MAX],[VL_NEGOCIO_MIN],[QTD_NEGOCIO]);
				-----------------------------------------------------------------------------------------
				IF OBJECT_ID('tempdb..#FECHAMENTO_NR_NEGOCIO') IS NOT NULL DROP TABLE #FECHAMENTO_NR_NEGOCIO;
				SELECT CD_CLIENTE
					 , DT_NEGOCIO
					 , CD_PAPEL
					 , MAX(NR_NEGOCIO) FECHAMENTO_NR_NEGOCIO 
				 INTO #FECHAMENTO_NR_NEGOCIO
				 FROM #ST_CORRETAGEM_ORDEM
			 GROUP BY CD_CLIENTE
					 , DT_NEGOCIO
					 , CD_PAPEL;
			
				-----------------------------------------------------------------------------------------
				IF OBJECT_ID('tempdb..#NEGOCIO_FECHAMENTO') IS NOT NULL DROP TABLE #NEGOCIO_FECHAMENTO;
				SELECT A.CD_CLIENTE
					 , A.DT_NEGOCIO
					 , A.CD_PAPEL
					 , VL_NEGOCIO VL_NEGOCIO_FECHAMENTO 
				  INTO #NEGOCIO_FECHAMENTO
				  FROM #ST_CORRETAGEM_ORDEM A 
			INNER JOIN #FECHAMENTO_NR_NEGOCIO B 
					ON A.CD_CLIENTE = B.CD_CLIENTE 
				   AND A.CD_PAPEL = B.CD_PAPEL 
				   AND A.NR_NEGOCIO = B.FECHAMENTO_NR_NEGOCIO
				   AND A.DT_NEGOCIO = B.DT_NEGOCIO;				 
				
				 IF OBJECT_ID('tempdb..#NC_ATUAL') IS NOT NULL DROP TABLE #NC_ATUAL;
				 SELECT 
			   DISTINCT A.CD_CLIENTE
					  , A.CD_PAPEL
					  , A.DT_NEGOCIO
					  , A.NR_NEGOCIO
					  , A.VL_NEGOCIO VL_NEGOCIO_ABERTURA 
					  , D.VL_NEGOCIO_FECHAMENTO
					  , B.VL_NEGOCIO_MIN
					  , B.VL_NEGOCIO_MAX	
					  , B.VL_NEGOCIO_AVG
					  , QTD_NEGOCIO QTD_NEGOCIO_CLIENTE
					  , PREMIN PRECO_MIN_MERCADO
					  , PREMAX PRECO_MAX_MERCADO			  
					  , QUATOT QTD_NEGOCIOS_MERCADO
					  , C.PREMED
					  , C.PREABE
					  , C.PREULT
					  , C.VOLUME_MERCADO
					  , C.PRAZOT
			
				   INTO #NC_ATUAL
				   FROM #ST_CORRETAGEM_ORDEM A 
			 INNER JOIN #NEGOCIO_ABERTURA B  
					 ON A.CD_CLIENTE = B.CD_CLIENTE 
					AND A.CD_PAPEL   = B.CD_PAPEL
					AND A.DT_NEGOCIO = B.DT_NEGOCIO
					AND A.NR_NEGOCIO = B.ABERTURA_NR_NEGOCIO

			  LEFT JOIN #VOLUME_MERCADO_ATUAL C 
					 ON A.CD_PAPEL   = C.CODNEG
					AND A.DT_NEGOCIO = C.DT_PERIODO
					AND A.TP_VCOTER  = C.PRAZOT

			 INNER JOIN #NEGOCIO_FECHAMENTO D
					 ON A.CD_PAPEL   = D.CD_PAPEL
					AND A.CD_CLIENTE = D.CD_CLIENTE
					AND A.DT_NEGOCIO = D.DT_NEGOCIO; 
				
					IF OBJECT_ID('tempdb..#NC') IS NOT NULL DROP TABLE #NC;
					SELECT A.CD_CLIENTE
						 , A.CD_PAPEL
						 , A.DT_NEGOCIO																	AS DT_NEGOCIO_DIA
						 , B.DT_PERIODO																	AS DT_NEGOCIO_ANT
						 , A.NR_NEGOCIO																	AS NR_NEGOCIO_DIA				
						 , A.VL_NEGOCIO_MIN																AS VL_NEGOCIO_MIN_DIA
						 , A.VL_NEGOCIO_MAX																AS VL_NEGOCIO_MAX_DIA
						 , A.VL_NEGOCIO_AVG																AS VL_NEGOCIO_AVG_DIA
						 , ISNULL(A.QTD_NEGOCIO_CLIENTE,0)												AS QTD_NEGOCIO_CLIENTE_DIA
						 , ISNULL(A.PRECO_MIN_MERCADO,0)												AS PRECO_MIN_MERCADO_DIA
						 , ISNULL(A.PRECO_MAX_MERCADO,0)												AS PRECO_MAX_MERCADO_DIA			  
						 , ISNULL(A.QTD_NEGOCIOS_MERCADO,0)												AS QTD_NEGOCIOS_MERCADO_DIA
						 , ISNULL(A.VL_NEGOCIO_ABERTURA,0)												AS VL_ABERTURA_CLIENTE_DIA
						 , ISNULL(B.VL_NEGOCIO_ABERTURA,0)												AS VL_ABERTURA_CLIENTE_ANT
						 , ISNULL(A.VL_NEGOCIO_FECHAMENTO,0)											AS VL_FECHAMENTO_CLIENTE_DIA
						 , ISNULL(B.VL_NEGOCIO_FECHAMENTO,0)											AS VL_FECHAMENTO_CLIENTE_ANT
						 , ISNULL(A.PREABE,0)															AS VL_ABERTURA_MERCADO_DIA
						 , ISNULL(B.PREABE,0)															AS VL_ABERTURA_MERCADO_ANT	
						 , ISNULL(A.PREMED,0)															AS VL_MED_MERCADO_DIA
						 , ISNULL(B.PREMED,0)															AS VL_MED_MERCADO_ANT						 
						 , ISNULL(A.PREULT,0)															AS VL_FECHAMENTO_MERCADO_DIA
						 , ISNULL(B.PREULT,0)															AS VL_FECHAMENTO_MERCADO_ANT						 
						 , ISNULL(A.VOLUME_MERCADO,0)													AS VOLUME_MERCADO_DIA
						 , ISNULL(B.VOLUME_MERCADO,0)													AS VOLUME_MERCADO_ANT
						 , (ISNULL(A.VL_NEGOCIO_FECHAMENTO,0) / NULLIF(A.VL_NEGOCIO_ABERTURA,0))   - 1  AS INTRADAY_CLIENTE
						 , (ISNULL(A.VL_NEGOCIO_ABERTURA,0)  /  NULLIF(B.VL_NEGOCIO_FECHAMENTO,0)) - 1  AS INTERDAY_CLIENTE
						 , (ISNULL(A.PREULT,0) / NULLIF(A.PREABE,0))	 - 1							AS INTRADAY_MERCADO
						 , (ISNULL(A.PREABE,0) / NULLIF(B.PREULT,0)) - 1								AS INTERDAY_MERCADO						 
						 , C.CD_CLIENTE_BRO															    AS CD_CLIENTE_BRO
						 , C.IN_LEILAO																	AS IN_LEILAO
						 , ISNULL(C.VOL_CLI_ATUAL,0)													AS VOL_CLI_ATUAL
						 , ISNULL(C.VOL_MED_ATUAL,0)													AS VOL_MED_ATUAL
						 , ISNULL(B.VOLUME,0)															AS VOL_CLI_ANT
						 , ISNULL(B.VOL_MED_ATUAL,0)													AS VOL_MED_ANT	
						 , ISNULL(A.PRAZOT,0)															AS PRAZOT
					  INTO #NC 
					  FROM #NC_ATUAL A
				 LEFT JOIN #ST_MANIPULACAO_BVSP_ANT B 
					    ON A.CD_CLIENTE = B.CD_CLIENTE
					   AND A.CD_PAPEL   = B.CD_PAPEL
				 LEFT JOIN #VOLUME_CLIENTE_ATUAL C
						ON A.CD_CLIENTE =C.CD_CLIENTE
					   AND A.CD_PAPEL = C.CD_PAPEL


		
			   DELETE FROM ST_MANIPULACAO_BVSP WHERE DT_PERIODO = @DT_PREGAO;
			 
			   INSERT INTO ST_MANIPULACAO_BVSP (DT_PERIODO,CD_CLIENTE,CD_CLIENTE_BRO,CD_PAPEL,INDICE_BVSP,PREMED,PREABE,PREULT,VOLUME,VOLUME_CLIENTE_ANT,VOL_MED_ATUAL,VARIACAO_CLIENTE,VARIACAO_CLIENTE_STRING
											   ,VOLUME_MERCADO,VOLUME_MERCADO_ANT,VARIACAO_MERCADO,VARIACAO_MERCADO_STRING,PERC_CLIENTE_MERCADO,PERC_CLIENTE_MERCADO_STRING,IND_LEILAO,VL_NEGOCIO_ABERTURA
											   ,VL_NEGOCIO_FECHAMENTO,VL_NEGOCIO_MIN,VL_NEGOCIO_MAX,VL_NEGOCIO_AVG,QTD_NEGOCIO,PRECO_MIN_MERCADO,PRECO_MAX_MERCADO,QTD_NEGOCIOS_MERCADO,INTRADAY_CLIENTE,INTRADAY_CLIENTE_STRING
											   ,INTERDAY_CLIENTE,INTERDAY_CLIENTE_STRING,INTRADAY_MERCADO,INTRADAY_MERCADO_STRING,INTERDAY_MERCADO,INTERDAY_MERCADO_STRING,PRAZOT)

					SELECT DT_NEGOCIO_DIA																									  AS DT_PERIODO 
						 , CD_CLIENTE																									      AS CD_CLIENTE
						 , CD_CLIENTE_BRO																								      AS CD_CLIENTE_BRO
						 , CD_PAPEL																											  AS CD_PAPEL
						 ,'N'																												  AS INDICE_BVSP
						 , VL_MED_MERCADO_DIA																								  AS PREMED
						 , VL_ABERTURA_MERCADO_DIA																							  AS PREABE
						 , VL_FECHAMENTO_MERCADO_DIA																						  AS PREULT
						 , SUM(VOL_CLI_ATUAL)																								  AS VOLUME
						 , ISNULL(SUM(VOL_CLI_ANT), 0)																						  AS VOLUME_CLIENTE_ANT
						 , ISNULL(SUM(VOL_MED_ATUAL), 0)																					  AS VOL_MED_ATUAL
						 , ISNULL(ISNULL(SUM(VOL_CLI_ATUAL), 0) / NULLIF(SUM(VOL_CLI_ANT), 0), 0)											  AS VARIACAO_CLIENTE
						 , CONVERT(VARCHAR,ISNULL(ISNULL(SUM(VOL_CLI_ATUAL), 0) / NULLIF(SUM(VOL_CLI_ANT), 0), 0) * 100)+'%'				  AS VARIACAO_CLIENTE_STRING
						 , MAX(VOLUME_MERCADO_DIA)																							  AS VOLUME_MERCADO
						 , ISNULL(MAX(VOLUME_MERCADO_ANT), 0)																				  AS VOLUME_MERCADO_ANT
						 , ISNULL(ISNULL(SUM(VOLUME_MERCADO_DIA), 0) / NULLIF(SUM(VOLUME_MERCADO_ANT), 0), 0)								  AS VARIACAO_MERCADO
						 , CONVERT(VARCHAR,ISNULL(ISNULL(SUM(VOLUME_MERCADO_DIA), 0) / NULLIF(SUM(VOLUME_MERCADO_ANT), 0), 0) * 100)+'%'	  AS VARIACAO_MERCADO_STRING
						 , ISNULL(SUM(VOL_CLI_ATUAL) / NULLIF(SUM(VOLUME_MERCADO_DIA), 0), 0)												  AS PERC_CLIENTE_MERCADO
						 , CONVERT(VARCHAR,ISNULL(SUM(VOL_CLI_ATUAL) / NULLIF(SUM(VOLUME_MERCADO_DIA), 0), 0) * 100)+'%'					  AS PERC_CLIENTE_MERCADO_STRING
						 , CASE WHEN MAX(IN_LEILAO) = 'N' THEN 'N' ELSE 'S'	END																  AS IND_LEILAO
						 , VL_ABERTURA_CLIENTE_DIA																							  AS VL_NEGOCIO_ABERTURA
						 , VL_FECHAMENTO_CLIENTE_DIA																						  AS VL_NEGOCIO_FECHAMENTO
						 , VL_NEGOCIO_MIN_DIA																								  AS VL_NEGOCIO_MIN
						 , VL_NEGOCIO_MAX_DIA																								  AS VL_NEGOCIO_MAX 
						  ,VL_NEGOCIO_AVG_DIA																								  AS VL_NEGOCIO_AVG 
						 , QTD_NEGOCIO_CLIENTE_DIA																							  AS QTD_NEGOCIO
						 , PRECO_MIN_MERCADO_DIA																							  AS PRECO_MIN_MERCADO
						 , PRECO_MAX_MERCADO_DIA																							  AS PRECO_MAX_MERCADO		  
						 , QTD_NEGOCIOS_MERCADO_DIA																							  AS QTD_NEGOCIOS_MERCADO
			  			 , ISNULL(INTRADAY_CLIENTE,0)																						  AS INTRADAY_CLIENTE
						 , CONVERT(VARCHAR,CAST(ISNULL(INTRADAY_CLIENTE,0) * 100 AS NUMERIC(17,3)))+'%'										  AS INTRADAY_CLIENTE_STRING
						 , ISNULL(INTERDAY_CLIENTE,0)																						  AS INTERDAY_CLIENTE
						 , CONVERT(VARCHAR,CAST(ISNULL(INTERDAY_CLIENTE,0) * 100 AS NUMERIC(17,3)))+'%'										  AS  INTERDAY_CLIENTE_STRING
						 , ISNULL(INTRADAY_MERCADO,0)																						  AS INTRADAY_MERCADO
						 , CONVERT(VARCHAR,CAST(ISNULL(INTRADAY_MERCADO,0) * 100 AS NUMERIC(17,3)))+'%'										  AS  INTRADAY_MERCADO_STRING
						 , ISNULL(INTERDAY_MERCADO,0)																						  AS INTERDAY_MERCADO
						 , CONVERT(VARCHAR,CAST(ISNULL(INTERDAY_MERCADO,0) * 100 AS NUMERIC(17,3)))+'%'										  AS INTERDAY_MERCADO_STRING	
						 , PRAZOT																											  AS PRAZOT
					  FROM #NC A 		
				  GROUP BY A.CD_CLIENTE
		 				 , A.DT_NEGOCIO_DIA
		 				 , A.CD_CLIENTE_BRO
		 				 , A.CD_PAPEL
						 , VL_MED_MERCADO_DIA
		 				 , VL_ABERTURA_CLIENTE_DIA 
						 , VL_ABERTURA_MERCADO_DIA
						 , VL_FECHAMENTO_MERCADO_DIA
		 				 , VL_FECHAMENTO_CLIENTE_DIA
		 				 , VL_NEGOCIO_MIN_DIA
		 				 , VL_NEGOCIO_MAX_DIA
						 , VL_NEGOCIO_AVG_DIA
		 				 , QTD_NEGOCIO_CLIENTE_DIA
		 				 , PRECO_MIN_MERCADO_DIA
		 				 , PRECO_MAX_MERCADO_DIA			  
		 				 , QTD_NEGOCIOS_MERCADO_DIA
						 , VL_NEGOCIO_AVG_DIA
						 , VL_FECHAMENTO_CLIENTE_DIA
						 , VL_ABERTURA_CLIENTE_DIA
						 , INTRADAY_CLIENTE
						 , INTERDAY_CLIENTE
						 , INTRADAY_MERCADO
						 , INTERDAY_MERCADO
						 , PRAZOT;

		----------------------------------------------------------------------------------------------------------------------		
		SET @DT_PREGAO = DATEADD(DAY,1,@DT_PREGAO)
	END

	-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_MANIPULACAO_BVSP', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_MANIPULACAO_BVSP]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END
/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_MANIPULACAO_BVSP_PADRAO