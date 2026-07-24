CREATE PROCEDURE [dbo].[PR_PRETERICAO] 
(@INICIO SMALLDATETIME, @FIM SMALLDATETIME,@CD_CLIENTE   VARCHAR(160)
,@CD_BROKER VARCHAR(160),@NR_ORDEM INT,@QTDPORPAGINA INT,@PAGINA INT)
 
AS
----versão final
 
--DECLARE @QTDPORPAGINA INT,
--        @PAGINA       INT,
--        @INICIO       SMALLDATETIME,
--        @FIM          SMALLDATETIME,
--        @CD_CLIENTE   VARCHAR(160),
--        @CD_BROKER    VARCHAR(160),
--        @NR_ORDEM     INT;
--SET @QTDPORPAGINA = NULL;
--SET @PAGINA       = NULL;
--SET @INICIO     = '20260201';
--SET @FIM        = '20260205';
--SET @CD_CLIENTE = '';
--SET @CD_BROKER  = '';
--SET @NR_ORDEM   = ''--0;
--SET @CD_CLIENTE = ISNULL(@CD_CLIENTE, '');
--SET @CD_BROKER  = ISNULL(@CD_BROKER,  '');
--SET @NR_ORDEM   = ISNULL(@NR_ORDEM,   0);

DECLARE @LIM_DESVIO_R$   DECIMAL(18,6) = 0.01;
DECLARE @LIM_DESVIO_PCT  DECIMAL(10,4) = 0.1;

;WITH
ordens_unicas AS
(
    SELECT
        a.DT_NEGOCIO,
        a.CD_PAPEL,
        a.CD_NATOPE,
        a.CD_CLIENTE,
        a.NR_NEGOCIO,
        a.NR_SEQORD,
        a.VL_NEGOCIO,
        a.VL_TOTNEG,
        MIN(b.CD_CLIENTE_BRO) AS CD_CLIENTE_BRO
    FROM ST_CORRETAGEM_ORDEM (NOLOCK) a
    INNER JOIN ST_TORCOM     (NOLOCK) b
        ON  a.DT_NEGOCIO = b.DT_NEGOCIO
        AND a.CD_CLIENTE = b.CD_CLIENTE
        AND a.NR_NEGOCIO = b.NR_NEGOCIO
        AND a.CD_NATOPE  = b.CD_NATOPE
    WHERE a.DT_NEGOCIO >= @INICIO
      AND a.DT_NEGOCIO <  DATEADD(DAY, 1, @FIM)
      AND (@CD_CLIENTE = '' OR a.CD_CLIENTE     = @CD_CLIENTE)
      AND (@CD_BROKER  = '' OR b.CD_CLIENTE_BRO = @CD_BROKER)
      AND (@NR_ORDEM   = 0  OR a.NR_SEQORD      = @NR_ORDEM)
    GROUP BY
        a.DT_NEGOCIO, a.CD_PAPEL, a.CD_NATOPE, a.CD_CLIENTE,
        a.NR_NEGOCIO, a.NR_SEQORD, a.VL_NEGOCIO, a.VL_TOTNEG
)
,ordem_negocio AS
(
    SELECT
        DT_NEGOCIO,
        CD_PAPEL,
        CD_NATOPE,
        CD_CLIENTE,
        NR_NEGOCIO,
        MIN(NR_SEQORD)                                                      AS NR_SEQORD,
        SUM(VL_TOTNEG) / NULLIF(SUM(VL_TOTNEG / NULLIF(VL_NEGOCIO, 0)), 0) AS VL_PRECO
    FROM ordens_unicas
    GROUP BY DT_NEGOCIO, CD_PAPEL, CD_NATOPE, CD_CLIENTE, NR_NEGOCIO
)
,contexto_neg AS
(
    SELECT
        DT_NEGOCIO,
        CD_PAPEL,
        CD_NATOPE,
        CD_CLIENTE_BRO,
        COUNT(DISTINCT NR_NEGOCIO) AS qt_negocios
    FROM ordens_unicas
    GROUP BY DT_NEGOCIO, CD_PAPEL, CD_NATOPE, CD_CLIENTE_BRO
)
,contexto_cli AS
(
    SELECT
        b.DT_NEGOCIO,
        b.CD_NEGOCIO                     AS CD_PAPEL,
        b.CD_NATOPE,
        b.CD_CLIENTE_BRO,
        COUNT(DISTINCT b.CD_CLIENTE_FIN) AS qt_clientes_bloco
    FROM ST_TORCOM (NOLOCK) b
    WHERE b.DT_NEGOCIO >= @INICIO
      AND b.DT_NEGOCIO <  DATEADD(DAY, 1, @FIM)
      AND (@CD_CLIENTE = '' OR b.CD_CLIENTE     = @CD_CLIENTE)
      AND (@CD_BROKER  = '' OR b.CD_CLIENTE_BRO = @CD_BROKER)
      AND (@NR_ORDEM   = 0  OR b.NR_SEQORD      = @NR_ORDEM)
    GROUP BY b.DT_NEGOCIO, b.CD_NEGOCIO, b.CD_NATOPE, b.CD_CLIENTE_BRO
)
,contexto AS
(
    SELECT
        COALESCE(n.DT_NEGOCIO,     c.DT_NEGOCIO)     AS DT_NEGOCIO,
        COALESCE(n.CD_PAPEL,       c.CD_PAPEL)        AS CD_PAPEL,
        COALESCE(n.CD_NATOPE,      c.CD_NATOPE)       AS CD_NATOPE,
        COALESCE(n.CD_CLIENTE_BRO, c.CD_CLIENTE_BRO)  AS CD_CLIENTE_BRO,
        n.qt_negocios,
        c.qt_clientes_bloco
    FROM contexto_neg n
    FULL OUTER JOIN contexto_cli c
        ON  n.DT_NEGOCIO     = c.DT_NEGOCIO
        AND n.CD_PAPEL       = c.CD_PAPEL
        AND n.CD_NATOPE      = c.CD_NATOPE
        AND n.CD_CLIENTE_BRO = c.CD_CLIENTE_BRO
)
,broker AS
(
    SELECT
        u1.DT_NEGOCIO,
        u1.CD_PAPEL,
        u1.CD_NATOPE,
        u1.CD_CLIENTE_BRO     AS cd_broker,
        MIN(u1.NR_SEQORD)     AS nr_ordem,
        MIN(u1.VL_NEGOCIO)    AS preco_min,
        MAX(u1.VL_NEGOCIO)    AS preco_max,
        CAST(SUM(u1.VL_TOTNEG / NULLIF(u1.VL_NEGOCIO, 0)) AS BIGINT)        AS Qtd_Broke,
        SUM(u1.VL_TOTNEG) / NULLIF(SUM(u1.VL_TOTNEG / NULLIF(u1.VL_NEGOCIO, 0)), 0) AS PM_Broker,
        STUFF((
            SELECT ' / ' + CAST(u2.NR_NEGOCIO AS VARCHAR(50))
            FROM ordens_unicas u2
            WHERE u2.DT_NEGOCIO     = u1.DT_NEGOCIO
              AND u2.CD_PAPEL       = u1.CD_PAPEL
              AND u2.CD_NATOPE      = u1.CD_NATOPE
              AND u2.CD_CLIENTE_BRO = u1.CD_CLIENTE_BRO
            ORDER BY u2.NR_NEGOCIO
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 3, '')  AS Negocios
    FROM ordens_unicas u1
    GROUP BY u1.DT_NEGOCIO, u1.CD_PAPEL, u1.CD_NATOPE, u1.CD_CLIENTE_BRO
)
,analitico AS
(
    SELECT
        b.DT_NEGOCIO,
        COALESCE(o.CD_PAPEL, b.CD_NEGOCIO)  AS CD_PAPEL,
        b.CD_NATOPE,
        b.CD_CLIENTE_BRO  AS cd_broker,
        b.CD_CLIENTE_FIN  AS cd_cliente_fin,
        MIN(o.NR_SEQORD)  AS nr_ordem,
        CAST(SUM(b.QT_QTDESP) AS BIGINT)                              AS Qtd_Cliente,
        SUM(o.VL_PRECO * b.QT_QTDESP) / NULLIF(SUM(b.QT_QTDESP), 0) AS PM_Cliente
    FROM ST_TORCOM (NOLOCK) b
    LEFT JOIN ordem_negocio o
        ON  o.DT_NEGOCIO = b.DT_NEGOCIO
        AND o.CD_CLIENTE = b.CD_CLIENTE
        AND o.NR_NEGOCIO = b.NR_NEGOCIO
        AND o.CD_NATOPE  = b.CD_NATOPE
    WHERE b.DT_NEGOCIO >= @INICIO
      AND b.DT_NEGOCIO <  DATEADD(DAY, 1, @FIM)
      AND (@CD_CLIENTE = '' OR b.CD_CLIENTE     = @CD_CLIENTE)
      AND (@CD_BROKER  = '' OR b.CD_CLIENTE_BRO = @CD_BROKER)
      AND (@NR_ORDEM   = 0  OR b.NR_SEQORD      = @NR_ORDEM)
    GROUP BY
        b.DT_NEGOCIO, COALESCE(o.CD_PAPEL, b.CD_NEGOCIO), b.CD_NATOPE,
        b.CD_CLIENTE_BRO, b.CD_CLIENTE_FIN
)
SELECT
    --COALESCE(br.DT_NEGOCIO,  an.DT_NEGOCIO)     AS Data,
	  CONVERT(VARCHAR(10), COALESCE(br.DT_NEGOCIO, an.DT_NEGOCIO), 103)  AS Data,
    COALESCE(br.CD_PAPEL,    an.CD_PAPEL)                 AS Ticker,
    CASE COALESCE(br.CD_NATOPE, an.CD_NATOPE)
        WHEN 'C' THEN 'C'
        WHEN 'V' THEN 'V'
        ELSE NULL
    END                                                   AS "Natureza Oper",
    COALESCE(br.cd_broker,   an.cd_broker)                AS "Cod Broker",
    an.cd_cliente_fin                                     AS "Cod Cliente Fin",
    COALESCE(br.nr_ordem,    an.nr_ordem)                 AS "NR Ordem",
    ctx.qt_negocios                                       AS "Qtd Negocios",
    ctx.qt_clientes_bloco                                 AS "Qtd Clientes Ordens",
    CAST(COALESCE(br.preco_min, 0) AS DECIMAL(18,2))      AS "Preco Min",
    CAST(COALESCE(br.preco_max, 0) AS DECIMAL(18,2))      AS "Preco Max",
    br.Qtd_Broke                                          AS "Qtd Exec Broker",
    CAST(br.PM_Broker AS DECIMAL(18,4))                   AS "PMP Broker",      -- 4 casas
    an.Qtd_Cliente                                        AS "Qtd Alocada Cliente Fin",
    CAST(an.PM_Cliente AS DECIMAL(18,4))                  AS "PMP Cliente",     -- 4 casas
    SUM(an.Qtd_Cliente) OVER (
        PARTITION BY
            COALESCE(br.DT_NEGOCIO, an.DT_NEGOCIO),
            COALESCE(br.CD_PAPEL,   an.CD_PAPEL),
            COALESCE(br.CD_NATOPE,  an.CD_NATOPE),
            COALESCE(br.cd_broker,  an.cd_broker))        AS "Qtd Total Alocada",
    SUM(an.Qtd_Cliente) OVER (
        PARTITION BY
            COALESCE(br.DT_NEGOCIO, an.DT_NEGOCIO),
            COALESCE(br.CD_PAPEL,   an.CD_PAPEL),
            COALESCE(br.CD_NATOPE,  an.CD_NATOPE),
            COALESCE(br.cd_broker,  an.cd_broker)
    ) - ISNULL(br.Qtd_Broke, 0)                           AS "Diferenca Qtd",
    FORMAT(CAST(an.PM_Cliente - br.PM_Broker AS DECIMAL(18,4)),'f','pt-br')   AS "Diferenca PMP",  -- 4 casas
    FORMAT(CAST(ABS(an.PM_Cliente - br.PM_Broker) AS DECIMAL(18,4)),'f','pt-br')   AS Spread,            -- 4 casas

 
	
	CAST(
    CAST(ABS(CASE WHEN ISNULL(br.PM_Broker, 0) <> 0
                  THEN (an.PM_Cliente - br.PM_Broker) / br.PM_Broker * 100
                  ELSE NULL END) AS DECIMAL(10,2))
AS VARCHAR(20)) + ' %'                                AS "Spread Pct",

    CASE WHEN ABS(an.PM_Cliente - br.PM_Broker) > @LIM_DESVIO_R$
              AND ABS(CASE WHEN ISNULL(br.PM_Broker, 0) <> 0
                           THEN (an.PM_Cliente - br.PM_Broker) / br.PM_Broker * 100
                           ELSE 0 END) > @LIM_DESVIO_PCT
         THEN 'SIM'
         ELSE 'NAO' END     AS "Possivel Diverg"


FROM broker  br
FULL OUTER JOIN analitico an
    ON  br.DT_NEGOCIO  = an.DT_NEGOCIO
    AND br.CD_PAPEL    = an.CD_PAPEL
    AND br.CD_NATOPE   = an.CD_NATOPE
    AND br.cd_broker   = an.cd_broker
LEFT JOIN contexto ctx
    ON  COALESCE(br.DT_NEGOCIO, an.DT_NEGOCIO) = ctx.DT_NEGOCIO
    AND COALESCE(br.CD_PAPEL,   an.CD_PAPEL)   = ctx.CD_PAPEL
    AND COALESCE(br.CD_NATOPE,  an.CD_NATOPE)  = ctx.CD_NATOPE
    AND COALESCE(br.cd_broker,  an.cd_broker)  = ctx.CD_CLIENTE_BRO


ORDER BY
    COALESCE(br.DT_NEGOCIO, an.DT_NEGOCIO),
    COALESCE(br.CD_PAPEL,   an.CD_PAPEL),
    COALESCE(br.CD_NATOPE,  an.CD_NATOPE)





OFFSET (ISNULL(@PAGINA,1) - 1) * CASE WHEN ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS
FETCH NEXT CASE WHEN ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS ONLY;