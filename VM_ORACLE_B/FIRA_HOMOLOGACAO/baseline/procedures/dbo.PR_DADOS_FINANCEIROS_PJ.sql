CREATE PROCEDURE [dbo].[PR_DADOS_FINANCEIROS_PJ]
    @CD_ANO         VARCHAR(4)  = NULL,
    @DS_MES         VARCHAR(20) = NULL,
    @CD_CLIENTE     INT         = NULL,
    @QTDPORPAGINA   INT         = NULL,
    @PAGINA         INT         = NULL
AS

--DECLARE @CD_CLIENTE     VARCHAR(10),
--    @DS_MES         VARCHAR(20) ,  -- mês da referência (ex: JANEIRO), opcional
--    @CD_ANO         VARCHAR(4)  ,  -- ano da referência (ex: 2026), opcional
--   @QTDPORPAGINA   INT,
--    @PAGINA      INT

--	SET @CD_ANO = '2025'
--	SET @DS_MES = 'DEZEMBRO'
--	SET @CD_CLIENTE =''
BEGIN
    SET NOCOUNT ON;

    DECLARE @inicio SMALLDATETIME, @fim SMALLDATETIME;
    SET @inicio = (SELECT EOMONTH(MAX(DT_PERIODO),-2) FROM VDASH_ALERTAS);
    SET @fim    = (SELECT EOMONTH(MAX(DT_PERIODO),-1) FROM VDASH_ALERTAS);

    DECLARE @ALERTAS_PERIODO TABLE (CD_CLIENTE VARCHAR(10) PRIMARY KEY);

    IF ISNULL(@DS_MES,'') <> '' AND ISNULL(@CD_ANO,'') <> ''
        INSERT INTO @ALERTAS_PERIODO (CD_CLIENTE)
        SELECT DISTINCT CAST(K.[Cód. Cliente] AS VARCHAR(10))
        FROM ST_RELATORIO_PAINEL_ALERTAS_CVM (NOLOCK) K
        WHERE LTRIM(RTRIM(LEFT(K.REFERENCIA, CHARINDEX('/',K.REFERENCIA)-1)))                          = @DS_MES
          AND LTRIM(RTRIM(SUBSTRING(K.REFERENCIA, CHARINDEX('/',K.REFERENCIA)+1, LEN(K.REFERENCIA)))) = @CD_ANO
          AND K.[PF / PJ] = 'PJ';

    DECLARE @PATRIMONIO TABLE (CD_CLIENTE VARCHAR(10), PATRIMONIO NUMERIC(38,2));
    INSERT INTO @PATRIMONIO (CD_CLIENTE, PATRIMONIO)
    SELECT CAST(XX.CD_CLIENTE AS VARCHAR(10)), ISNULL(CAST(SUM(VAL_BENS) AS NUMERIC(38,2)),0)
    FROM ST_PATRIMONIO_LIQ XX
    WHERE DATA = (SELECT MAX(DATA) FROM ST_PATRIMONIO_LIQ YY
                  WHERE DATA > @INICIO AND DATA <= @FIM
                  AND DATEPART(WEEKDAY,DATA) NOT IN (7,1))
      AND CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN CD_CLIENTE ELSE @CD_CLIENTE END
    GROUP BY XX.CD_CLIENTE;

    IF ISNULL(@DS_MES,'') <> '' AND ISNULL(@CD_ANO,'') <> ''
    BEGIN
        ;WITH DADOS_DEDUP AS (
            SELECT b.*,
                   p.PATRIMONIO AS PATRIMONIO_CALC,
                   ROW_NUMBER() OVER (PARTITION BY b.CD_CLIENTE ORDER BY b.CD_CLIENTE) AS RN
            FROM ST_DADOS_FINANCEIROS_PJ b
            INNER JOIN @ALERTAS_PERIODO AP ON CAST(b.CD_CLIENTE AS VARCHAR(10)) = AP.CD_CLIENTE
            LEFT  JOIN @PATRIMONIO p ON CAST(b.CD_CLIENTE AS VARCHAR(10)) = p.CD_CLIENTE
            WHERE b.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN b.CD_CLIENTE ELSE @CD_CLIENTE END
        )
        SELECT
             CASE WHEN TP_SITUAC='BL' THEN 'BLOQUEADO' WHEN TP_SITUAC='EN' THEN 'ENCERRADO'
                  WHEN TP_SITUAC='AT' THEN 'ATIVO' ELSE 'INATIVO' END  AS [SITUAÇÃO CAD. GERAL]
            ,CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CNPJ(CPF)                                      AS CNPJ
            ,CD_ASSESSOR                                                 AS [CÓD. ASSESSOR]
            ,ISNULL(NM_ASSESSOR,'-')                                     AS ASSESSOR
            ,ISNULL(CD_BANCO,'-')                                        AS BANCO
            ,ISNULL(CD_AGENCIA,'-')                                      AS [AGÊNCIA]
            ,ISNULL(CONTA,'-')                                           AS CONTA
            ,FORMAT(ISNULL(PATRIMONIO_CALC,0),'f','pt-br')               AS PATRIMONIO
            ,DS_ATIV                                                     AS ATIVIDADE
            ,CASE WHEN IN_CONTR_BOLSA ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BOLSA]
            ,CASE WHEN IN_CONTR_BMF   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BMF]
            ,CASE WHEN IN_CONTR_SOCIAL='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. SOCIAL]
            ,CASE WHEN IN_CONTR_TER   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. TER]
            ,CASE WHEN IN_CONTR_TST   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. TST]
            ,CASE WHEN IN_CONTR_BTC   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BTC]
            ,CASE WHEN IN_CONTA_MARGEM='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTA MARGEM]
        FROM DADOS_DEDUP
        WHERE RN = 1
        ORDER BY 1
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,100000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,100000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        SELECT
             CASE WHEN B.TP_SITUAC='BL' THEN 'BLOQUEADO' WHEN B.TP_SITUAC='EN' THEN 'ENCERRADO'
                  WHEN B.TP_SITUAC='AT' THEN 'ATIVO' ELSE 'INATIVO' END AS [SITUAÇÃO CAD. GERAL]
            ,B.CD_CLIENTE                                                AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CNPJ(CPF)                                      AS CNPJ
            ,B.CD_ASSESSOR                                               AS [CÓD. ASSESSOR]
            ,ISNULL(NM_ASSESSOR,'-')                                     AS ASSESSOR
            ,ISNULL(CD_BANCO,'-')                                        AS BANCO
            ,ISNULL(CD_AGENCIA,'-')                                      AS [AGÊNCIA]
            ,ISNULL(CONTA,'-')                                           AS CONTA
            ,FORMAT(ISNULL(p.PATRIMONIO,0),'f','pt-br')                  AS PATRIMONIO
            ,B.DS_ATIV                                                   AS ATIVIDADE
            ,CASE WHEN IN_CONTR_BOLSA ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BOLSA]
            ,CASE WHEN IN_CONTR_BMF   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BMF]
            ,CASE WHEN IN_CONTR_SOCIAL='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. SOCIAL]
            ,CASE WHEN IN_CONTR_TER   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. TER]
            ,CASE WHEN IN_CONTR_TST   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. TST]
            ,CASE WHEN IN_CONTR_BTC   ='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTR. BTC]
            ,CASE WHEN IN_CONTA_MARGEM='S' THEN 'SIM' ELSE 'NÃO' END   AS [IN. CONTA MARGEM]
        FROM ST_DADOS_FINANCEIROS_PJ B
        LEFT JOIN @PATRIMONIO p ON CAST(B.CD_CLIENTE AS VARCHAR(10)) = p.CD_CLIENTE
        WHERE B.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN B.CD_CLIENTE ELSE @CD_CLIENTE END
        ORDER BY 1
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,100000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,100000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
END