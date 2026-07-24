CREATE   PROCEDURE [dbo].[PR_ANALISE_MESA_REATIL_BMF]
(
    @inicio        smalldatetime,
    @fim           smalldatetime,
    @cd_cliente    varchar(10)  = NULL,
    @CD_SERIE      varchar(10)  = NULL,
    @CD_COMMOD     varchar(10)  = NULL,
    @QTDPORPAGINA  int          = 100000000,
    @PAGINA        int          = 1
)
AS



--declare @inicio smalldatetime, @fim smalldatetime,@cd_cliente varchar(10), @CD_SERIE VARCHAR(10), @CD_COMMOD VARCHAR(10) , @QTDPORPAGINA INT, @PAGINA INT	
--set @inicio ='20251201'
--set @fim ='20251231'
--set @cd_cliente = '71' 
--set @CD_COMMOD='WIN' 
--set @CD_SERIE='' 


BEGIN
    SET NOCOUNT ON;

    /* =========================
       Tabela temporária Clientes
       ========================= */
    DROP TABLE IF EXISTS #V_CLIENTE_TODOS;

    SELECT CD_CLIENTE, NM_CLIENTE, IN_POLITICO_EXP
    INTO #V_CLIENTE_TODOS
    FROM ST_DADOS_BASICOS_PF

    UNION
    SELECT CD_CLIENTE, NM_CLIENTE, IN_POLITICO_EXP
    FROM ST_DADOS_BASICOS_PJ;

    /* =========================
       CTE – Pré-agregação BMF
       ========================= */
    ;WITH NEGOCIO_AGRUPADO AS
    (
        SELECT
            CODCLI,
            NR_NEGOCIO,
            DT_PREGAO,
            MAX(HR_NEGOCIO)   AS HR_NEGOCIO,
            MAX(CD_OPERADOR) AS CD_OPERADOR
        FROM ST_BMF_NEGOCIOS_TMP1
        GROUP BY CODCLI, NR_NEGOCIO, DT_PREGAO
    )
    SELECT  
        CONVERT(date, A.DT_NEGOCIO)                    AS [DATA],
        A.CD_CLIENTE                                   AS [CÓD. DO CLIENTE],
        AN.NM_CLIENTE                                  AS [Nome do Cliente],
        A.NR_NEGOCIO                                   AS [NR NEGOCIO],
        NA.HR_NEGOCIO                                  AS [HR NEGOCIO],
        A.CD_COMMOD                                    AS [COMMODITIES],
        ISNULL(A.CD_SERIE,'-')                         AS [SERIE],
        CASE A.CD_NATOPE 
            WHEN 'C' THEN 'Compra' 
            ELSE 'Venda' 
        END                                            AS [OPERACAO],
        A.QT_QTDDET                                    AS [QTD. CONTRATOS],
        CAST(A.PR_NEGOCIO AS float)                    AS [PRECO],
        CAST(A.VL_CORNEG AS float)                     AS [CORRETAGEM],
        CASE 
            WHEN A.CD_NATOPE = 'C' AND A.VL_VALOPE < 0 THEN -A.VL_VALOPE
            WHEN A.CD_NATOPE = 'V' AND A.VL_VALOPE > 0 THEN -A.VL_VALOPE
            ELSE A.VL_VALOPE 
        END                                            AS [VL AJUSTE],
        NA.CD_OPERADOR                                 AS [CÓD. OPERADOR],
        ISNULL(A.CD_CONTRAPARTE,0)                     AS [CÓD. CORRETORA],
        ISNULL(COR.NM_CORRET,'-')                      AS [NOME DA CORRETORA],
        ISNULL(AN.IN_POLITICO_EXP,'')                  AS [PEP],
        A.TP_NEGOCIO                                   AS [TIPO NEGOCIO]
    FROM ST_BMF_NEGOCIOS_NC A
    LEFT JOIN NEGOCIO_AGRUPADO NA
           ON NA.CODCLI     = A.CD_CLIENTE
          AND NA.NR_NEGOCIO = A.NR_NEGOCIO
          AND NA.DT_PREGAO  = A.DT_NEGOCIO
    LEFT JOIN #V_CLIENTE_TODOS AN 
           ON A.CD_CLIENTE = AN.CD_CLIENTE
    LEFT JOIN ST_CORRETORA COR 
           ON A.CD_CONTRAPARTE = COR.CD_CORRET
    WHERE
        A.CD_CLIENTE = CASE WHEN ISNULL(@cd_cliente,'') = '' THEN A.CD_CLIENTE ELSE @cd_cliente END
    AND A.DT_NEGOCIO >= @inicio
    AND A.DT_NEGOCIO <  DATEADD(DAY, 1, @fim)
    AND A.TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
    AND A.CD_COMMOD  = case when ISNULL(@CD_COMMOD,'') = '' then A.CD_COMMOD else @CD_COMMOD end
	AND ISNULL(A.CD_SERIE,'')   = case when ISNULL(@CD_SERIE,'') = '' then ISNULL(A.CD_SERIE,'') else @CD_SERIE end
    ORDER BY A.DT_NEGOCIO DESC

    OFFSET (ISNULL(@PAGINA,1) - 1) * CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS
	FETCH NEXT CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS ONLY;

END