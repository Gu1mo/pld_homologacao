CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_08_EMISSOR_VINCULADO] @PREGAO SMALLDATETIME, @AUX INT
--WITH RECOMPILE	
AS



/*************************************************************************************************
REGRA DO ALERTA:
Obs Gobbo:
QUANDO FOR POR NO CLIENTE PRECISA FAZER UMA COMPARAÇÃO COM A LISTA DE ATIVOS QUE TEMOS 
NESSE ALERTA COM OS ATIVOS DO CLIENTE PARA VERIFICAR SE FICOU ALGUM GAP DE ATIVOS. 
Vai ter tipos de ativos que não estarão pois não iremos contemplar neste primeiro 
momento como BDR's e FII's

*************************************************************************************************/


 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_EMISSOR_VINCULADO_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_EMISSOR_VINCULADO_PADRAO](
	[DATA] DATE, 
	[CD_CLIENTE] INT NULL,
	[TICKER] CHAR(4) NULL,
	[CNPJ] VARCHAR(20) NULL,
	[RAZAO_SOCIAL] VARCHAR(800) NULL,
	[QTD_COMPRA] INT NULL,
	[QTD_VENDA] INT NULL,
	[RESULTADO] NUMERIC(17,2) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
-- Executar de verdade (automático)
EXEC dbo.usp_sync_table_schema_add_alter_2012
     @schema_name='dbo',
     @base_table='ST_ALERT_EMISSOR_VINCULADO',
     @execute=1,
     @allow_drop=1,
     @apply_rename_map=1;
  

/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))

DECLARE @DT_REF DATE = DATEADD(DAY, - @AUX, @PREGAO);
DECLARE @DT_INI_MES DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, @PREGAO) - 1, 0);


 DROP TABLE IF EXISTS #NEGOCIACAO;
		SELECT CD_CLIENTE
			 , CD_PAPEL
			 , SUBSTRING(CD_PAPEL,1,4) AS TICKER
			 , DT_NEGOCIO
			 , NR_NEGOCIO
			 , CD_NATOPE
			 , QT_MULTIPLICADOR
			 , VL_NEGOCIO
			 , FT_VALORIZACAO
		  INTO #NEGOCIACAO
		  FROM ST_CORRETAGEM_ORDEM A
		 WHERE DT_NEGOCIO >= @DT_INI_MES 
		   AND DT_NEGOCIO <= @DT_REF;

 DROP TABLE IF EXISTS #CADASTRO
		SELECT CD_CLIENTE
			 , CD_CNPJ_EMPRESA 
		  INTO #CADASTRO
		  FROM ST_DADOS_BASICOS_PF 
		  
		  UNION
		   
		SELECT CD_CLIENTE
			 , CD_CNPJ_EMPRESA 
		  FROM ST_DADOS_BASICOS_PJ;

 DROP TABLE IF EXISTS #NEGOCIOS_COM_EMPRESA;
		SELECT A.CD_CLIENTE
			 , A.CD_PAPEL
			 , A.TICKER
			 , A.DT_NEGOCIO
			 , A.NR_NEGOCIO
			 , A.CD_NATOPE
			 , A.QT_MULTIPLICADOR
			 , A.VL_NEGOCIO
			 , A.FT_VALORIZACAO
			 , B.CNPJ
			 , B.RAZAO_SOCIAL
		  INTO #NEGOCIOS_COM_EMPRESA
		  FROM #NEGOCIACAO A 
		  JOIN ListaAcoes  B 
		    ON A.TICKER = B.TICKER
		  JOIN #CADASTRO C
		    ON A.CD_CLIENTE = C.CD_CLIENTE 
		   AND B.CNPJ = C.CD_CNPJ_EMPRESA;
		  
	DROP TABLE IF EXISTS #VOLUME;
		   SELECT CD_CLIENTE
				, CNPJ
				, TICKER
				, RAZAO_SOCIAL
				, CD_NATOPE
				, COUNT(DISTINCT NR_NEGOCIO) AS QTD_NEGOCIOS
				, SUM(QT_MULTIPLICADOR * ((VL_NEGOCIO)*(FT_VALORIZACAO))) AS VOLUME
			 INTO #VOLUME
			 FROM #NEGOCIOS_COM_EMPRESA
		 GROUP BY CD_CLIENTE
				, CNPJ
				, TICKER
				, RAZAO_SOCIAL
				, CD_NATOPE;

	  DROP TABLE IF EXISTS #COMPRA;
			 SELECT CD_CLIENTE
				  , CNPJ
				  , TICKER
				  , RAZAO_SOCIAL
				  , CD_NATOPE
				  , QTD_NEGOCIOS
				  , VOLUME
			   INTO #COMPRA
			   FROM #VOLUME 
			  WHERE CD_NATOPE = 'C';

      DROP TABLE IF EXISTS #VENDA;
			 SELECT CD_CLIENTE
				  , CNPJ
				  , TICKER
				  , RAZAO_SOCIAL
				  , CD_NATOPE
				  , QTD_NEGOCIOS
				  , VOLUME
			   INTO #VENDA
			   FROM #VOLUME WHERE CD_NATOPE = 'V';

		DROP TABLE IF EXISTS #CD_CLIENTE;
			  SELECT 
			DISTINCT CD_CLIENTE , TICKER , RAZAO_SOCIAL, CNPJ
				INTO #CD_CLIENTE 
				FROM #VOLUME;

DELETE FROM ST_ALERT_EMISSOR_VINCULADO WHERE DATA = DATEADD(DAY,- @AUX , @PREGAO)

INSERT INTO ST_ALERT_EMISSOR_VINCULADO 
(DATA,CD_CLIENTE,TICKER,CNPJ,RAZAO_SOCIAL,QTD_COMPRA,QTD_VENDA,RESULTADO)

	 SELECT DATEADD(DAY,- @AUX , @PREGAO) AS DATA 
		  , A.CD_CLIENTE 
		  , A.TICKER
		  , A.CNPJ
		  , A.RAZAO_SOCIAL
		  , ISNULL(B.QTD_NEGOCIOS,0) AS QTD_COMPRA
		  , ISNULL(C.QTD_NEGOCIOS,0) AS QTD_VENDA
		  , (ISNULL(C.VOLUME,0) - ISNULL(B.VOLUME,0)) AS RESULTADO
	   FROM #CD_CLIENTE A
  LEFT JOIN #COMPRA B
		 ON A.CD_CLIENTE = B.CD_CLIENTE
		 AND A.TICKER = B.TICKER
  LEFT JOIN #VENDA C
		 ON A.CD_CLIENTE = C.CD_CLIENTE
		 AND A.TICKER = C.TICKER;
/******* fim do processo de carga do alerta **********/

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_EMISSOR_VINCULADO', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_EMISSOR_VINCULADO
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_EMISSOR_VINCULADO_PADRAO