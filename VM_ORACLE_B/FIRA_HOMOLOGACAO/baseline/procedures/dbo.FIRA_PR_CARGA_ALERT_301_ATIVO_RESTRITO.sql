--VERIFICAR SE ESTÁ FALTANDO DT_CARGA NAS TABELAS DO FIRALINK
--drop table if exists ARQ_CAP_003_01_DIREITOS_SUBS;
--CREATE TABLE ARQ_CAP_003_01_DIREITOS_SUBS (
--    denom_soc      VARCHAR(200)  NULL,
--    nm_pregao      VARCHAR(200)  NULL,
--    isin           VARCHAR(200)  NULL,
--    cod_neg        VARCHAR(200)  NULL,
--    n_emiss        VARCHAR(200)  NULL,
--    classe         VARCHAR(200)  NULL,
--    tp_oferta      VARCHAR(200)  NULL,
--    dt_lib_prof    VARCHAR(50)   NULL,
--    dt_lib_qual    VARCHAR(50)   NULL,
--    dt_lib_var     VARCHAR(50)   NULL,
--    criado_em_utc  DATE          NULL,
--    DT_FIRA        DATETIME      NULL DEFAULT (GETDATE()),
--    DT_CARGA       DATE         NULL
--);


-- ALTER TABLE ARQ_CAP_004_01_BDR_ETF_RV
-- ADD DT_CARGA       DATE         NULL

-- ALTER TABLE ARQ_CAP_004_01_BDRS_ACOES
-- ADD DT_CARGA       DATE         NULL

CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_ATIVO_RESTRITO]
    @PREGAO SMALLDATETIME,
    @AUX    INT
--WITH ENCRYPTION
AS

--DECLARE @PREGAO SMALLDATETIME, @AUX INT

--SET @PREGAO = '20260505'

--SET @AUX = (SELECT DAY(@PREGAO))
/*************************************************************************************************
REGRA DO ALERTA:
Existe umas tabelas que pegamos da B3.
Caso o cliente não for qualificado e negociar um ativo dessas tabelas ele cai no alerta.

CORREÇÃO 02/06/2026:
- A cláusula de data na #CLIENTE_ALERTA usava "DT_LIB_VAR IS NOT NULL AND negocio < DT_LIB_VAR",
  o que excluía ativos sem data de liberação (NULL = sempre restrito) — gerando falsos negativos.
- Corrigido para: NULL = sempre restrito → alerta; ou negócio < data de liberação → alerta.
- Adicionado CASE WHEN para usar DT_LIB_VAR (não qualificado) ou DT_LIB_QUAL (qualificado),
  preparando para eventual extensão do alerta a investidores qualificados.
- Join do cliente (c) movido antes do join dos ativos restritos (a) para permitir
  referência a c.IN_QUALIFICADO dentro do ON da tabela #ATIVOS_RESTRITOS.
*************************************************************************************************/

-- ==============================================================
-- passo 1 — verificação / criação da tabela destino
-- ==============================================================
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_ATIVO_RESTRITO_PADRAO]')
      AND type IN (N'U')
)
CREATE TABLE [dbo].[ST_ALERT_ATIVO_RESTRITO_PADRAO] (
    [DATA]          DATE         NULL,
    [CD_CLIENTE]    INT          NOT NULL,
    IN_QUALIFICADO  CHAR(1)      NULL,
    QTDE_NEGOCIOS   INT          NULL,
    QTDE_ATIVOS     INT          NULL,
    NEGOCIOS        VARCHAR(MAX) NULL,
    [DT_FIRA]       DATETIME     NULL
) ON [PRIMARY];

EXEC dbo.usp_sync_table_schema_add_alter_2012
    @schema_name = 'dbo',
    @base_table  = 'ST_ALERT_ATIVO_RESTRITO',
    @execute     = 1,
    @allow_drop  = 1,
    @apply_rename_map = 1;

-- ==============================================================
-- passo 2 — variáveis de período
-- ==============================================================
SET @AUX = DAY(@PREGAO);

DECLARE @dt_ini DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, -1, @PREGAO)), 0); -- 1º dia do mês anterior
DECLARE @dt_fim DATE = DATEADD(MONTH, 1, @dt_ini);                                          -- 1º dia do mês atual (exclusive)

-- ==============================================================
-- passo 3 — ativos restritos (B3)
-- ==============================================================
DROP TABLE IF EXISTS #ATIVOS_RESTRITOS;

SELECT DISTINCT
       LTRIM(RTRIM(COD_NEG))                          AS CD_PAPEL,
       CAST(NULL AS VARCHAR(100))                     AS TIPO_INV,
       CAST(NULL AS VARCHAR(100))                     AS PUB_ALVO,
       CAST(dt_lib_neg_para_comprad_p AS DATE)        AS DT_LIB_PROF,
       CAST(dt_lib_neg_para_comprad_q AS DATE)        AS DT_LIB_QUAL,
       CAST(dt_lib_neg_para_comprad_v AS DATE)        AS DT_LIB_VAR,
       CAST('ARQ_CAP_002_01_INFO_SOBRE_OFERTAS' AS VARCHAR(100)) AS ORIGEM_RESTRICAO
INTO #ATIVOS_RESTRITOS
FROM ARQ_CAP_002_01_INFO_SOBRE_OFERTAS

WHERE cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_002_01_INFO_SOBRE_OFERTAS)
UNION

SELECT DISTINCT

       LTRIM(RTRIM(COD_NEG)) AS CD_PAPEL,

       CAST(NULL AS VARCHAR(100)) AS TIPO_INV,

       CAST(NULL AS VARCHAR(100)) AS PUB_ALVO,

       CAST(dt_lib_prof AS DATE) AS DT_LIB_PROF,

       CAST(dt_lib_qual AS DATE) AS DT_LIB_QUAL,

       CAST(DT_LIB_VAR AS DATE) AS DT_LIB_VAR,

       CAST('ARQ_CAP_003_01_DIREITOS_SUBS' AS VARCHAR(100)) AS ORIGEM_RESTRICAO

FROM ARQ_CAP_003_01_DIREITOS_SUBS

 WHERE cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_003_01_DIREITOS_SUBS)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(COD_NEG)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS VARCHAR(100)),
       CAST(DT_LIB_PROF AS DATE),
       CAST(DT_LIB_QUAL AS DATE),
       CAST(DT_LIB_VAR  AS DATE),
       CAST('ARQ_CAP_003_01_INFO_SOBRE_OFERTAS' AS VARCHAR(100))
FROM ARQ_CAP_003_01_INFO_SOBRE_OFERTAS
 WHERE cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_003_01_INFO_SOBRE_OFERTAS)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(COD_NEG)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS VARCHAR(100)),
       CAST(dt_lib_prof AS DATE),
       CAST(dt_lib_qual AS DATE),
       CAST(dt_lib_var  AS DATE),
       CAST('ARQ_CAP_001_01' AS VARCHAR(100))
FROM ARQ_CAP_001_01
 WHERE cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_001_01)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(COD_NEG)),
       CAST(NULL AS VARCHAR(100)),
       LTRIM(RTRIM(pub_alvo)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_003_01_FII_ESTOQUE' AS VARCHAR(100))
FROM ARQ_CAP_003_01_FII_ESTOQUE
WHERE LTRIM(RTRIM(pub_alvo)) IN (
    'Investidor Qualificado',
    'Investidor Profissional',
    'Investidor Qualificado e Profissional'
)
and  cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_003_01_FII_ESTOQUE)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(COD_NEG)),
       CAST(NULL AS VARCHAR(100)),
       LTRIM(RTRIM(pub_alvo)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_003_01_FIDC_ESTOQUE' AS VARCHAR(100))
FROM ARQ_CAP_003_01_FIDC_ESTOQUE
WHERE LTRIM(RTRIM(pub_alvo)) IN (
    'Investidor Qualificado',
    'Investidor Profissional',
    'Investidor Qualificado e Profissional'
)
and  cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_003_01_FIDC_ESTOQUE)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(ticker_bdr)),
       LTRIM(RTRIM(tipo_inv)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_004_01_BDR_ETF_RV' AS VARCHAR(100))
FROM ARQ_CAP_004_01_BDR_ETF_RV
WHERE LTRIM(RTRIM(tipo_inv)) = 'Investidor Qualificado'
and cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_004_01_BDR_ETF_RV)

UNION

SELECT DISTINCT
       LTRIM(RTRIM(ticker_bdr)),
       LTRIM(RTRIM(tipo_inv)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_004_01_BDR_ETF_COMM' AS VARCHAR(100))
FROM ARQ_CAP_004_01_BDR_ETF_COMM
WHERE LTRIM(RTRIM(tipo_inv)) = 'Investidor Qualificado'

and cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_004_01_BDR_ETF_COMM)


UNION

SELECT DISTINCT
       LTRIM(RTRIM(ticker_bdr)),
       LTRIM(RTRIM(tipo_inv)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_004_01_BDR_ETF_RF' AS VARCHAR(100))
FROM ARQ_CAP_004_01_BDR_ETF_RF
WHERE LTRIM(RTRIM(tipo_inv)) = 'Investidor Qualificado'
and cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_004_01_BDR_ETF_RF)
UNION

SELECT DISTINCT
       LTRIM(RTRIM(ticker_bdr)),
       LTRIM(RTRIM(tipo_inv)),
       CAST(NULL AS VARCHAR(100)),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST(NULL AS DATE),
       CAST('ARQ_CAP_004_01_BDRS_ACOES' AS VARCHAR(100))
FROM ARQ_CAP_004_01_BDRS_ACOES
WHERE LTRIM(RTRIM(tipo_inv)) = 'Investidor Qualificado'
and cast(criado_em_utc as date) = (select cast(max(criado_em_utc) as date) from ARQ_CAP_004_01_BDRS_ACOES);
-- ==============================================================
-- passo 4 — negócios do período
-- ==============================================================
DROP TABLE IF EXISTS #NEGOCIOS;

-- BOVESPA
SELECT
       LTRIM(RTRIM(CD_PAPEL))              AS CD_PAPEL,
       CD_CLIENTE,
       DT_NEGOCIO,
       NR_NEGOCIO,
       'BOVESPA'                           AS SEGMENTO
INTO #NEGOCIOS
FROM ST_CORRETAGEM_ORDEM
WHERE DT_NEGOCIO >= @dt_ini
  AND DT_NEGOCIO  < @dt_fim

UNION ALL

-- BMF
SELECT
       LTRIM(RTRIM(CD_COMMOD + CD_SERIE))  AS CD_PAPEL,
       CD_CLIENTE,
       DT_NEGOCIO,
       NR_NEGOCIO,
       'BMF'                               AS SEGMENTO
FROM ST_BMF_NEGOCIOS_NC
WHERE DT_NEGOCIO >= @dt_ini
  AND DT_NEGOCIO  < @dt_fim
  AND TP_NEGOCIO IN ('NORMAL', 'DAYTRADE', 'DAY TRADE');

-- ==============================================================
-- passo 5 — cruza negócios x ativos restritos x clientes
--
-- CORREÇÃO: join do cliente (c) vem ANTES do join dos ativos (a)
-- para permitir uso de c.IN_QUALIFICADO no ON de #ATIVOS_RESTRITOS.
--
-- Lógica de data corrigida:
--   Para origens com controle de prazo (ARQ_CAP_001_01 / 002 / 003 INFO_SOBRE_OFERTAS):
--     - NULL na data de liberação = ativo NUNCA liberado para esse perfil → deve alertar
--     - Data preenchida e negócio ANTES da data          → deve alertar
--     - Data preenchida e negócio NA DATA OU APÓS        → não alerta (já liberado)
--   Data usada conforme perfil:
--     - IN_QUALIFICADO = 'N' (varejo)      → DT_LIB_VAR
--     - IN_QUALIFICADO = 'S' (qualificado) → DT_LIB_QUAL
-- ==============================================================
DROP TABLE IF EXISTS #CLIENTE_ALERTA;

SELECT
       n.CD_CLIENTE,
       n.CD_PAPEL,
       n.DT_NEGOCIO,
       n.SEGMENTO,
       c.IN_QUALIFICADO,
       n.NR_NEGOCIO
INTO #CLIENTE_ALERTA
FROM #NEGOCIOS n
JOIN (
    SELECT DISTINCT CD_CLIENTE, IN_QUALIFICADO FROM ST_DADOS_BASICOS_PF WHERE IN_QUALIFICADO = 'N'
    UNION ALL
    SELECT DISTINCT CD_CLIENTE, IN_QUALIFICADO FROM ST_DADOS_BASICOS_PJ WHERE IN_QUALIFICADO = 'N'
) c
  ON c.CD_CLIENTE = n.CD_CLIENTE
JOIN #ATIVOS_RESTRITOS a
  ON a.CD_PAPEL = n.CD_PAPEL
 AND (
        -- Origens sem controle de prazo: qualquer negócio já gera alerta
        a.ORIGEM_RESTRICAO NOT IN (
            'ARQ_CAP_001_01',
            'ARQ_CAP_002_01_INFO_SOBRE_OFERTAS',
            'ARQ_CAP_003_01_INFO_SOBRE_OFERTAS',
                  'ARQ_CAP_003_01_DIREITOS_SUBS'
        )
        OR (
            -- Origens com controle de prazo:
            -- NULL = nunca liberado para o perfil → alerta
            -- negócio antes da data de liberação  → alerta
            CASE
                WHEN c.IN_QUALIFICADO = 'N' THEN a.DT_LIB_VAR
                WHEN c.IN_QUALIFICADO = 'S' THEN a.DT_LIB_QUAL
            END IS NULL
            OR CAST(n.DT_NEGOCIO AS DATE) < CASE
                WHEN c.IN_QUALIFICADO = 'N' THEN a.DT_LIB_VAR
                WHEN c.IN_QUALIFICADO = 'S' THEN a.DT_LIB_QUAL
            END
        )
     );

-- ==============================================================
-- passo 6 — deduplica por negócio
-- ==============================================================
DROP TABLE IF EXISTS #BASE;

SELECT DISTINCT
       CD_CLIENTE,
       CD_PAPEL,
       NR_NEGOCIO,
       IN_QUALIFICADO
INTO #BASE
FROM #CLIENTE_ALERTA;

-- ==============================================================
-- passo 7 — contagem por cliente
-- ==============================================================
DROP TABLE IF EXISTS #CONTAGEM;

SELECT
       CD_CLIENTE,
       COUNT(NR_NEGOCIO)        AS QTDE_NEGOCIOS,
       COUNT(DISTINCT CD_PAPEL) AS QTDE_ATIVOS,
       MIN(IN_QUALIFICADO)      AS IN_QUALIFICADO
INTO #CONTAGEM
FROM #BASE
GROUP BY CD_CLIENTE;

-- ==============================================================
-- passo 8 — lista de negócios por ativo
-- ==============================================================
DROP TABLE IF EXISTS #NEG_POR_ATIVO;

SELECT
       CD_CLIENTE,
       CD_PAPEL,
       STRING_AGG(CONVERT(VARCHAR(MAX), NR_NEGOCIO), ',')
           WITHIN GROUP (ORDER BY NR_NEGOCIO) AS LISTA_NEGOCIOS
INTO #NEG_POR_ATIVO
FROM #BASE
GROUP BY CD_CLIENTE, CD_PAPEL;

-- ==============================================================
-- passo 9 — resumo final
-- ==============================================================
DROP TABLE IF EXISTS #RESUMO;

SELECT
       c.CD_CLIENTE,
       c.QTDE_NEGOCIOS,
       c.QTDE_ATIVOS,
       c.IN_QUALIFICADO,
       STRING_AGG(
           n.CD_PAPEL + ': ' + n.LISTA_NEGOCIOS,
           '; '
       ) WITHIN GROUP (ORDER BY n.CD_PAPEL) AS NEGOCIOS
INTO #RESUMO
FROM #CONTAGEM c
JOIN #NEG_POR_ATIVO n ON n.CD_CLIENTE = c.CD_CLIENTE
GROUP BY
       c.CD_CLIENTE,
       c.QTDE_NEGOCIOS,
       c.QTDE_ATIVOS,
       c.IN_QUALIFICADO;

-- ==============================================================
-- passo 10 — carga na tabela destino
---- ==============================================================
DELETE FROM ST_ALERT_ATIVO_RESTRITO
WHERE DATA = CAST(@PREGAO - @AUX AS DATE);

INSERT INTO ST_ALERT_ATIVO_RESTRITO (DATA, CD_CLIENTE, IN_QUALIFICADO, QTDE_NEGOCIOS, QTDE_ATIVOS, NEGOCIOS)
SELECT
       CAST(@PREGAO - @AUX AS DATE) AS DATA,
       r.CD_CLIENTE,
       r.IN_QUALIFICADO,
       r.QTDE_NEGOCIOS,
       r.QTDE_ATIVOS,
       r.NEGOCIOS
FROM #RESUMO r
--where r.CD_CLIENTE not in (38768,31287,135899,21424,114462,109757,103149,37630,8660964)
ORDER BY r.CD_CLIENTE;

-- ==============================================================
-- passo 11 — marca DT_FIRA
-- ==============================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();

IF COL_LENGTH(N'dbo.ST_ALERT_ATIVO_RESTRITO', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE dbo.ST_ALERT_ATIVO_RESTRITO
    SET    DT_FIRA = @__dt_fira_now
    WHERE  DT_FIRA IS NULL;
END;