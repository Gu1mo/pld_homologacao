CREATE PROCEDURE [dbo].[PR_MUDANCA_REPENTINA]  @ANOMES INT , @CD_CLIENTE VARCHAR(160),@QTDPORPAGINA INT,@PAGINA INT
WITH RECOMPILE
AS

-- (dentro da procedure)
SET NOCOUNT ON;
SET XACT_ABORT ON;

--DECLARE @ANOMES INT = 202512;
--DECLARE @CD_CLIENTE INT = NULL;      -- NULL = todos
--DECLARE @QTDPORPAGINA INT = 1000;
--DECLARE @PAGINA INT = 1;

-----------------------------------------------------------------------
-- 1) Descobrir janelas por DATA (evita join pesado com ST_PERIODO)
-----------------------------------------------------------------------
DECLARE @dt_ini_mes DATE, @dt_fim_mes DATE;

SELECT
    @dt_ini_mes = MIN(p.dt_periodo)
FROM ST_PERIODO p
WHERE p.cd_anomes = @ANOMES;

-- fim do mês (exclusivo)
SELECT
    @dt_fim_mes = DATEADD(DAY, 1, MAX(p.dt_periodo))
FROM ST_PERIODO p
WHERE p.cd_anomes = @ANOMES;

-- Janela “6M” (no seu script é 180 dias a partir do primeiro dia do mês)
DECLARE @dt_ini_6m DATE = DATEADD(DAY, -180, @dt_ini_mes);
DECLARE @dt_fim_6m DATE = DATEADD(DAY, -1,  @dt_ini_mes);  -- até véspera do mês atual

-- Mantém seus anomes para exibição (sem usar no filtro pesado)
DECLARE @anomes_anual_ini INT, @anomes_anual_fim INT;

SELECT @anomes_anual_fim = MAX(cd_anomes)
FROM ST_PERIODO
WHERE dt_periodo = DATEADD(DAY, -1, @dt_ini_mes);

SELECT @anomes_anual_ini = MAX(cd_anomes)
FROM ST_PERIODO
WHERE dt_periodo = @dt_ini_6m;

-----------------------------------------------------------------------
-- 2) Clientes (evita DISTINCT/UNION ALL duplicando custo)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS #V_CLIENTE_TODOS;

SELECT cd_cliente, MAX(nm_cliente) AS nm_cliente
INTO #V_CLIENTE_TODOS
FROM (
    SELECT cd_cliente, nm_cliente FROM ST_DADOS_BASICOS_PF
    UNION ALL
    SELECT cd_cliente, nm_cliente FROM ST_DADOS_BASICOS_PJ
) x
GROUP BY cd_cliente;

CREATE CLUSTERED INDEX IX1 ON #V_CLIENTE_TODOS (cd_cliente);

-----------------------------------------------------------------------
-- 3) Captura do mês atual em temp table (sem DISTINCT + com filtro SARG)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS #MES_RAW;

SELECT
    @ANOMES AS cd_anomes,
    a.cd_cliente,
    CASE
        WHEN a.tp_mercado IN ('FRA','LEI','VIS','LNC','ETF','IER','CET') THEN 'VIS'
        WHEN a.tp_mercado = 'TER' THEN 'TER'
        WHEN a.tp_mercado IN ('OPV','OPC','EOV','EOC','OPD','OPF') THEN 'OPC'
        ELSE a.tp_mercado
    END AS cd_tp_mercado
INTO #MES_RAW
FROM ST_CORRETAGEM_ORDEM a
WHERE a.dt_negocio >= @dt_ini_mes
  AND a.dt_negocio <  @dt_fim_mes
  AND A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'') = '' THEN CD_CLIENTE ELSE @CD_CLIENTE END

UNION ALL

SELECT
    @ANOMES AS cd_anomes,
    x.cd_cliente,
    CASE
        WHEN x.cd_mercad IN ('DIS','SPT') THEN 'SPT'
        WHEN x.cd_mercad IN ('FUT','VFU') THEN 'FUT'
        WHEN x.cd_mercad = 'BMF' THEN 'BMF'
        WHEN x.cd_mercad IN ('OPD','OPF') THEN 'OPC'
        ELSE x.cd_mercad
    END AS cd_tp_mercado
FROM ST_BMF_NEGOCIOS_NC x
WHERE x.tp_negocio IN ('NORMAL','DAY TRADE','DAYTRADE')
  AND x.dt_negocio >= @dt_ini_mes
  AND x.dt_negocio <  @dt_fim_mes
  AND x.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'') = '' THEN CD_CLIENTE ELSE @CD_CLIENTE END;

-- Índice pra acelerar agregação por cliente
CREATE CLUSTERED INDEX IX1 ON #MES_RAW (cd_cliente, cd_tp_mercado);

-----------------------------------------------------------------------
-- 4) Captura dos 6 meses anteriores (mesma lógica)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS #MES_ANT_RAW;

SELECT
    @anomes_anual_ini AS dt_ini_ant,
    @anomes_anual_fim AS dt_fim_ant,
    a.cd_cliente,
    CASE
        WHEN a.tp_mercado IN ('FRA','LEI','VIS','LNC','ETF','IER','CET') THEN 'VIS'
        WHEN a.tp_mercado = 'TER' THEN 'TER'
        WHEN a.tp_mercado IN ('OPV','OPC','EOV','EOC','OPD','OPF') THEN 'OPC'
        ELSE a.tp_mercado
    END AS cd_tp_mercado_ant
INTO #MES_ANT_RAW
FROM ST_CORRETAGEM_ORDEM a
WHERE a.dt_negocio >= @dt_ini_6m
  AND a.dt_negocio <= @dt_fim_6m
  AND A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'') = '' THEN CD_CLIENTE ELSE @CD_CLIENTE END

UNION ALL

SELECT
    @anomes_anual_ini,
    @anomes_anual_fim,
    x.cd_cliente,
    CASE
        WHEN x.cd_mercad IN ('DIS','SPT') THEN 'SPT'
        WHEN x.cd_mercad IN ('FUT','VFU') THEN 'FUT'
        WHEN x.cd_mercad = 'BMF' THEN 'BMF'
        WHEN x.cd_mercad IN ('OPD','OPF') THEN 'OPC'
        ELSE x.cd_mercad
    END AS cd_tp_mercado_ant
FROM ST_BMF_NEGOCIOS_NC x
WHERE x.tp_negocio IN ('NORMAL','DAY TRADE','DAYTRADE')
  AND x.dt_negocio >= @dt_ini_6m
  AND x.dt_negocio <= @dt_fim_6m
  AND x.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'') = '' THEN CD_CLIENTE ELSE @CD_CLIENTE END;

CREATE CLUSTERED INDEX IX1 ON #MES_ANT_RAW (cd_cliente, cd_tp_mercado_ant);

-----------------------------------------------------------------------
-- 5) Agregar uma vez por cliente (evita subselect correlacionado)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS #MES_AGG;
SELECT
    g.cd_anomes,
    g.cd_cliente,
    mercado_atual =
        STUFF((
            SELECT ' | ' + CONVERT(varchar(50), x.cd_tp_mercado)
            FROM (
                SELECT DISTINCT cd_anomes, cd_cliente, cd_tp_mercado
                FROM #MES_RAW
            ) x
            WHERE x.cd_anomes  = g.cd_anomes
              AND x.cd_cliente = g.cd_cliente
            ORDER BY x.cd_tp_mercado
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 3, '')  -- remove o primeiro ' | '
INTO #MES_AGG
FROM (
    SELECT DISTINCT cd_anomes, cd_cliente
    FROM #MES_RAW
) g;

CREATE UNIQUE CLUSTERED INDEX IX1 ON #MES_AGG (cd_anomes, cd_cliente);

DROP TABLE IF EXISTS #MES_ANT_AGG;
SELECT
    g.dt_ini_ant,
    g.dt_fim_ant,
    g.cd_cliente,
    mercado_anterior =
        STUFF((
            SELECT ' | ' + CONVERT(varchar(50), x.cd_tp_mercado_ant)
            FROM (
                SELECT DISTINCT dt_ini_ant, dt_fim_ant, cd_cliente, cd_tp_mercado_ant
                FROM #MES_ANT_RAW
            ) x
            WHERE x.dt_ini_ant = g.dt_ini_ant
              AND x.dt_fim_ant = g.dt_fim_ant
              AND x.cd_cliente = g.cd_cliente
            ORDER BY x.cd_tp_mercado_ant
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 3, '')  -- remove o primeiro ' | '
INTO #MES_ANT_AGG
FROM (
    SELECT DISTINCT dt_ini_ant, dt_fim_ant, cd_cliente
    FROM #MES_ANT_RAW
) g
CREATE UNIQUE CLUSTERED INDEX IX1 ON #MES_ANT_AGG (dt_ini_ant, dt_fim_ant, cd_cliente);

-----------------------------------------------------------------------
-- 6) Select final + paginação (sem DISTINCT)
-----------------------------------------------------------------------
SELECT
    a.cd_cliente AS [CÓD. CLIENTE],
    c.nm_cliente AS [NOME DO CLIENTE],
    a.cd_anomes  AS [DATA ATUAL],
    ISNULL(a.mercado_atual, '') AS [MERCADO ATUAL],
    @anomes_anual_ini AS [DATA INÍCIO 6M],
    @anomes_anual_fim AS [DATA FIM 6M],
    ISNULL(b.mercado_anterior, '') AS [MERCADO ANTERIOR]
FROM #MES_AGG a
LEFT JOIN #MES_ANT_AGG b
  ON b.cd_cliente = a.cd_cliente
 AND b.dt_ini_ant = @anomes_anual_ini
 AND b.dt_fim_ant = @anomes_anual_fim
LEFT JOIN #V_CLIENTE_TODOS c
  ON c.cd_cliente = a.cd_cliente

ORDER BY a.cd_cliente
OFFSET (CASE WHEN @PAGINA < 1 THEN 0 ELSE (@PAGINA - 1) END) * ISNULL(NULLIF(@QTDPORPAGINA, 0), 100000000) ROWS
FETCH NEXT ISNULL(NULLIF(@QTDPORPAGINA, 0), 100000000) ROWS ONLY;