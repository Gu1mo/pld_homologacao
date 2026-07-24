/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_08_OSCILACAO]    Script Date: 25/02/2026 15:50:21 ******/

CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_08_OSCILACAO] @PREGAO SMALLDATETIME, @AUX INT
as

/*************************************************************************************************
REGRA DO ALERTA:
Os clientes selecionados para a análise são aqueles apontados em alertas do grupo (CVM50/CVM62). 
Os alertas considerados são: omc bvsp, omc bmf, ranking daytrade bvsp, 
aml corretora bvsp e aml bvsp. São calculados a média e o desvio padrão dos parâmetros 
(oscilação média, oscilação máxima e diferença média) e os cortes são definidos como a (média + 3 desvio padrão).
Os clientes com valor acima do corte para qualquer um dos parâmetros são alertados.
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_OSCILACAO_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_OSCILACAO_PADRAO](
	[DATA] [date] NOT NULL,
	[CD_CLIENTE] [int] NULL,
	[ATIVO] [nvarchar](300) NULL,
	[ALERTADO_CVM50] [int] NOT NULL,
	[ALERTADO_CVM62] [int] NOT NULL,
	[PROPORCAO] [decimal](15, 4) NULL,
	[OSCILACAO_MEDIA] [decimal](15, 4) NULL,
	[OSCILACAO_MAX] [decimal](15, 4) NULL,
	[DIFERENCA_MEDIA] [decimal](15, 4) NULL,
	[ALERTADO_OSCILACAO] [int] NOT NULL,
	[ALERTADO_OSCILACAO_MAX] [int] NOT NULL,
	[ALERTADO_DIFERENCA] [int] NOT NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]


/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_OSCILACAO_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_OSCILACAO',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/





/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))



	DECLARE @CD_ANOMES INT		     = (SELECT MAX(CD_ANOMES) FROM ST_PERIODO  WHERE DT_PERIODO = DATEADD(DAY,-@AUX,@PREGAO));	
	DECLARE @DT_INICIO SMALLDATETIME = (SELECT MIN(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANOMES = @CD_ANOMES);
	DECLARE @DT_FIM    SMALLDATETIME = (SELECT MAX(DT_PERIODO) FROM ST_PERIODO WHERE DT_PERIODO = DATEADD(DAY,-@AUX,@PREGAO));

	--colunas solicitadas pelo saulo ([DATA],[ATIVO],[PRECO ABERTURA MERC],[PRECO MED MERC],[PRECO FECHAMENTO MERC],[VOLUME MERCADO],[PREÇO MED CLIENTE],[VOLUME CLIENTE])--1565
SELECT FORMAT(A.DT_PERIODO,'d','PT-BR')											AS [DATA]
		 , A.CD_CLIENTE															AS [COD CLIENTE]
		 --, B.NM_CLIENTE														AS [NOME CLIENTE]
		 , A.CD_PAPEL															AS [ATIVO]
		 --, A.CD_CLIENTE_BRO													AS [COD BROKER]
		 --, C.NM_CLIENTE														AS [NOME BROKER]
		 --, A.INDICE_BVSP														AS [INDICE BVSP]
		 , A.PREABE																AS [PRECO ABERTURA MERC]
		 --, A.PRECO_MAX_MERCADO												AS [PREÇO MAX MERC]
		 --, A.PRECO_MIN_MERCADO												AS [PREÇO MIN MERC]
		 , A.PREMED																AS [PRECO MED MERC]		 
		 , A.PREULT																AS [PRECO FECHAMENTO MERC]	
		 , A.VOLUME_MERCADO														AS [VOLUME MERCADO]
		 , A.VOLUME_MERCADO_ANT													AS [VOLUME MERCADO ANT]
		 --, A.VARIACAO_MERCADO_STRING											AS [VARIACAO MERCADO]
		 --, A.QTD_NEGOCIOS_MERCADO												AS [QTD NEG MERC]
		 , A.VOLUME																AS [VOLUME CLIENTE]
		 --, A.VOLUME_CLIENTE_ANT												AS [VOLUME CLIENTE ANT]
		 --, A.VOL_MED_ATUAL													AS [VOLUME MED]
		 --, A.VARIACAO_CLIENTE_STRING											AS [VARIACAO CLIENTE]		 
		 --, A.PERC_CLIENTE_MERCADO_STRING										AS [VARIACAO CLIENTE X MERC]
		 --, CASE WHEN A.IND_LEILAO = 'S' THEN 'SIM' ELSE 'NÃO' END				AS [LEILÃO]
		 --, A.VL_NEGOCIO_ABERTURA												AS [PRECO DE ABERTURA CLIENTE]
		 --, A.VL_NEGOCIO_FECHAMENTO											AS [PRECO DE FECHAMENTO CLIENTE]
		 --, A.VL_NEGOCIO_MIN													AS [PREÇO MIN CLIENTE]
		 --, A.VL_NEGOCIO_MAX													AS [PREÇO MAX CLIENTE]
		 , A.VL_NEGOCIO_AVG														AS [PREÇO MED CLIENTE]
		 , A.QTD_NEGOCIO														AS [QTD NEGOCIO CLIENTE]		 
		 --, A.INTRADAY_CLIENTE_STRING											AS [INTRADAY CLIENTE]
		 --, A.INTERDAY_CLIENTE_STRING											AS [INTERDAY CLIENTE]
		 --, A.INTRADAY_MERCADO_STRING											AS [INTRADAY MERCADO]
		 --, A.INTERDAY_MERCADO_STRING											AS [INTERDAY MERCADO]
	  INTO #CONTROLE_MANIPULACAO_BVSP --DROP TABLE #CONTROLE_MANIPULACAO_BVSP
	  FROM ST_MANIPULACAO_BVSP A
 --LEFT JOIN V_CLIENTE_TODOS B 
	--    ON A.CD_CLIENTE = B.CD_CLIENTE
 --LEFT JOIN V_CLIENTE_TODOS C 
	--    ON A.CD_CLIENTE_BRO = C.CD_CLIENTE

	 WHERE A.DT_PERIODO >= @DT_INICIO
	   AND A.DT_PERIODO <= @DT_FIM
	   ----AND A.CD_CLIENTE = CASE WHEN ISNULL(@CLIENTE,'') ='' THEN A.CD_CLIENTE ELSE @CLIENTE END
	   ----AND CD_PAPEL = CASE WHEN ISNULL(@CD_PAPEL,'') ='' THEN CD_PAPEL ELSE @CD_PAPEL END

  ORDER BY A.CD_CLIENTE
		 , A.CD_PAPEL
		 , A.DT_PERIODO;

		 --insert CVM62
		 --select distinct CD_CLIENTE, CD_PAPEL,1 ALERTADO INTO #ALERT_SPOOFING from ST_ALERT_SPOOFING_BOVESPA_02 WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)

		 --select distinct CD_CLIENTE, CD_PAPEL,1 ALERTADO INTO #ALERT_LAYRERING from ST_ALERT_LAYRERING_02 WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)
		 
		 select distinct CD_CLIENTE, CD_PAPEL,1 ALERTADO INTO #ALERT_OMC from ST_ALERT_OMC_01 WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)
		 
		 select distinct CD_CLIENTE, CD_NEGOCIO CD_PAPEL,1 ALERTADO INTO #ALERT_OMC_BMF from ST_ALERT_OMC_BMF_01 WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)	
		 
SELECT 
    CD_CLIENTE,
    CD_PAPEL,
    1 AS ALERTADOS_CVM62
INTO #ALERTAS_UNIFICADOS_CVM62
FROM (
    --SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_SPOOFING
    --UNION
    --SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_LAYRERING
    --UNION
    SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_OMC
    UNION
    SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_OMC_BMF
) AS uniao
--where CD_CLIENTE= '400628'

		--insert CVM50
		select distinct CD_CLIENTE, CD_PAPEL,1 ALERTADO INTO #ALERT_RANKING_DAYTRADE_BVSP from ST_ALERT_RANKING_DAYTRADE_BVSP WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)
		
		select distinct CD_CLIENTE, LTRIM(RTRIM(value)) AS CD_PAPEL,1 ALERTADO INTO #ALERT_MONEYPASS_CORRETORA from ST_ALERT_MONEYPASS_CORRETORA CROSS APPLY STRING_SPLIT(PAPEIS, ',') WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)
		
		select distinct CD_CLIENTE, LTRIM(RTRIM(value)) AS CD_PAPEL,1 ALERTADO INTO #ALERT_MONEYPASS02 from ST_ALERT_MONEYPASS_02 CROSS APPLY STRING_SPLIT(PAPEIS, ',') WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO)

SELECT 
    CD_CLIENTE,
    CD_PAPEL,
    1 AS ALERTADOS_CVM50
INTO #ALERTAS_UNIFICADOS_CVM50
FROM (
    SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_RANKING_DAYTRADE_BVSP
    UNION
    SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_MONEYPASS_CORRETORA
    UNION
    SELECT CD_CLIENTE, CD_PAPEL FROM #ALERT_MONEYPASS02
) AS uniao

SELECT distinct
    cd_cliente,
    LTRIM(RTRIM(value)) AS cd_papel,
    alertados_CVM50
INTO #ALERTAS_UNIFICADOS_CVM50_SPLIT
FROM #ALERTAS_UNIFICADOS_CVM50
CROSS APPLY STRING_SPLIT(cd_papel, ',')

-- 1. Volume do Cliente
SELECT 
    [COD CLIENTE], 
    [ATIVO], 
    SUM([VOLUME CLIENTE]) AS vol_cliente
INTO #VOLUME_CLIENTE
FROM #CONTROLE_MANIPULACAO_BVSP
GROUP BY [COD CLIENTE], [ATIVO];

-- 2. Volume do Mercado (distinto por Data e Ativo)
SELECT 
    [ATIVO], 
    SUM([VOLUME MERCADO]) AS vol_mercado
INTO #VOLUME_MERCADO
FROM (
    SELECT DISTINCT [DATA], [ATIVO], [VOLUME MERCADO]
    FROM #CONTROLE_MANIPULACAO_BVSP
) AS DistMerc
GROUP BY [ATIVO];

-- 3. Proporcao
SELECT 
    VC.[COD CLIENTE], 
    VC.[ATIVO], 
    CAST(VC.vol_cliente AS FLOAT) / NULLIF(VM.vol_mercado, 0) AS Proporcao
INTO #PROPORCAO
FROM #VOLUME_CLIENTE VC
LEFT JOIN #VOLUME_MERCADO VM
    ON VC.[ATIVO] = VM.[ATIVO];

-- 4. Oscilacao
SELECT 
    [COD CLIENTE], 
    [ATIVO],
    AVG(ABS([PRECO ABERTURA MERC] - [PRECO FECHAMENTO MERC]) / NULLIF([PRECO MED MERC], 0)) AS oscilacao_media,
    MAX(ABS([PRECO ABERTURA MERC] - [PRECO FECHAMENTO MERC]) / NULLIF([PRECO MED MERC], 0)) AS oscilacao_max,
    AVG(ABS([PREÇO MED CLIENTE] - [PRECO MED MERC])) AS diferenca_media
INTO #OSCILACAO
FROM #CONTROLE_MANIPULACAO_BVSP
GROUP BY [COD CLIENTE], [ATIVO];

-- 5. Cortes (valores únicos em variáveis)
SELECT 
    AVG(oscilacao_media) + 3 * STDEV(oscilacao_media) AS corte_oscilacao_media,
    AVG(oscilacao_max) + 3 * STDEV(oscilacao_max) AS corte_oscilacao_max,
    AVG(diferenca_media) + 3 * STDEV(diferenca_media) AS corte_diferenca_media
INTO #CORTES
FROM #OSCILACAO;

-- 6. Data máxima de oscilação
SELECT 
    [COD CLIENTE],
    [ATIVO],
    MAX([DATA]) AS data_max
INTO #RESULTADO_OSCILACAO_MAX
FROM (
    SELECT *, ABS([PRECO ABERTURA MERC] - [PRECO FECHAMENTO MERC]) / NULLIF([PRECO MED MERC], 0) AS oscilacao
    FROM #CONTROLE_MANIPULACAO_BVSP
) AS T
GROUP BY [COD CLIENTE], [ATIVO];

	DELETE FROM ST_ALERT_OSCILACAO WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO);

	INSERT INTO ST_ALERT_OSCILACAO (DATA,CD_CLIENTE,ATIVO,ALERTADO_CVM50,ALERTADO_CVM62,PROPORCAO,OSCILACAO_MEDIA,OSCILACAO_MAX,DIFERENCA_MEDIA,ALERTADO_OSCILACAO,ALERTADO_OSCILACAO_MAX,ALERTADO_DIFERENCA)
-- 7. Alerta Oscilacao Final
SELECT 
    CAST(@PREGAO-@AUX AS DATE)													AS DATA,
	ISNULL(C50.CD_CLIENTE, C62.CD_CLIENTE)										AS CD_CLIENTE,
    ISNULL(C50.CD_PAPEL, C62.CD_PAPEL)											AS ATIVO,
    ISNULL(C50.ALERTADOS_CVM50, 0)												AS ALERTADO_CVM50,
    ISNULL(C62.ALERTADOS_CVM62, 0)												AS ALERTADO_CVM62,
    CAST(ISNULL(P.Proporcao,0) AS DECIMAL(15,4))								AS PROPORCAO,
    CAST(ISNULL(O.oscilacao_media,0) AS DECIMAL(15,4))							AS OSCILACAO_MEDIA,
    CAST(ISNULL(O.oscilacao_max,0) AS DECIMAL(15,4))							AS OSCILACAO_MAX,
    CAST(ISNULL(O.diferenca_media,0) AS DECIMAL(15,4))							AS DIFERENCA_MEDIA,
    --D.data_max,
    CASE WHEN O.oscilacao_media >= C.corte_oscilacao_media THEN 1 ELSE 0 END	AS ALERTADO_OSCILACAO,
    CASE WHEN O.oscilacao_max >= C.corte_oscilacao_max THEN 1 ELSE 0 END		AS ALERTADO_OSCILACAO_MAX,
    CASE WHEN O.diferenca_media >= C.corte_diferenca_media THEN 1 ELSE 0 END	AS ALERTADO_DIFERENCA
FROM #ALERTAS_UNIFICADOS_CVM50_SPLIT C50
FULL OUTER JOIN #ALERTAS_UNIFICADOS_CVM62 C62
    ON C50.CD_CLIENTE = C62.CD_CLIENTE AND C50.CD_PAPEL = C62.CD_PAPEL
LEFT JOIN #PROPORCAO P
    ON ISNULL(C50.CD_CLIENTE, C62.CD_CLIENTE) = P.[COD CLIENTE] AND ISNULL(C50.CD_PAPEL, C62.CD_PAPEL) = P.ATIVO
LEFT JOIN #OSCILACAO O
    ON ISNULL(C50.CD_CLIENTE, C62.CD_CLIENTE) = O.[COD CLIENTE] AND ISNULL(C50.CD_PAPEL, C62.CD_PAPEL) = O.ATIVO
--LEFT JOIN #RESULTADO_OSCILACAO_MAX D
--    ON ISNULL(C50.CD_CLIENTE, C62.CD_CLIENTE) = D.[COD CLIENTE] AND ISNULL(C50.CD_PAPEL, C62.CD_PAPEL) = D.ATIVO
CROSS JOIN #CORTES C
WHERE 
     (CASE WHEN O.oscilacao_media >= C.corte_oscilacao_media THEN 1 ELSE 0 END) > 0--+
     and (CASE WHEN O.oscilacao_max >= C.corte_oscilacao_max THEN 1 ELSE 0 END) > 0-- +
     and (CASE WHEN O.diferenca_media >= C.corte_diferenca_media THEN 1 ELSE 0 END) > 0 --pra cair alguém, tive que por, >= 0, isso pro alerta de janeiro.

	 ORDER BY C50.CD_CLIENTE, C62.CD_CLIENTE;

/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_OSCILACAO', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_OSCILACAO
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_OSCILACAO_PADRAO