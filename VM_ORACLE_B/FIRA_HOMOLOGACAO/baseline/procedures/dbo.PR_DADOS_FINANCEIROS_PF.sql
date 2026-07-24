CREATE PROCEDURE [dbo].[PR_DADOS_FINANCEIROS_PF]
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
          AND K.[PF / PJ] = 'PF';

    DECLARE @PATRIMONIO TABLE (CD_CLIENTE INT, PATRIMONIO NUMERIC(38,2));
    INSERT INTO @PATRIMONIO (CD_CLIENTE, PATRIMONIO)
    SELECT XX.CD_CLIENTE, ISNULL(CAST(SUM(VAL_BENS) AS NUMERIC(38,2)),0)
    FROM ST_PATRIMONIO_LIQ XX
    WHERE DATA = (SELECT MAX(DATA) FROM ST_PATRIMONIO_LIQ YY
                  WHERE DATA > @INICIO AND DATA <= @FIM
                  AND DATEPART(WEEKDAY,DATA) NOT IN (7,1))
      AND CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN CD_CLIENTE ELSE @CD_CLIENTE END
    GROUP BY XX.CD_CLIENTE;

    IF ISNULL(@DS_MES,'') <> '' AND ISNULL(@CD_ANO,'') <> ''
    BEGIN
        ;WITH DADOS_DEDUP AS (
            SELECT a.*,
                   p.PATRIMONIO AS PATRIMONIO_CALC,
                   ROW_NUMBER() OVER (PARTITION BY a.CD_CLIENTE ORDER BY a.CD_CLIENTE) AS RN
            FROM ST_DADOS_FINANCEIROS_PF a
            INNER JOIN @ALERTAS_PERIODO AP ON CAST(a.CD_CLIENTE AS VARCHAR(10)) = AP.CD_CLIENTE
            LEFT  JOIN @PATRIMONIO p ON a.CD_CLIENTE = p.CD_CLIENTE
            WHERE a.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN a.CD_CLIENTE ELSE @CD_CLIENTE END
        )
        SELECT
             CASE WHEN TP_SITUAC='BL' THEN 'BLOQUEADO' WHEN TP_SITUAC='EN' THEN 'ENCERRADO'
                  WHEN TP_SITUAC='AT' THEN 'ATIVO' ELSE 'INATIVO' END  AS [SITUAÇÃO CAD. GERAL]
            ,CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CPF(CPF)                                       AS CPF
            ,ASSESSOR
            ,CD_BANCO                                                    AS BANCO
            ,AGENCIA                                                     AS [AGÊNCIA]
            ,CONTA
            ,CARGO
            ,PROF_ATIV                                                   AS [PROFISSÃO]
            ,FORMAT(ISNULL(PATRIMONIO_CALC,0),'f','pt-br')               AS PATRIMONIO
            ,IN_CONTR_BOLSA  AS [CONTRATO BOLSA]
            ,IN_CONTR_BMF    AS [CONTR. BMF]
            ,IN_CONTR_SOCIAL AS [CONTR. SOCIAL]
            ,IN_CONTR_OPC    AS [CONTR. OPCAO]
            ,IN_CONTR_TER    AS [CONTR. TERMO]
            ,IN_CONTR_TST    AS [CONTR. TST]
            ,IN_CONTR_BTC    AS [CONTR. BTC]
            ,IN_CONTA_MARGEM AS [CONTA MARGEM]
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
             CASE WHEN TP_SITUAC='BL' THEN 'BLOQUEADO' WHEN TP_SITUAC='EN' THEN 'ENCERRADO'
                  WHEN TP_SITUAC='AT' THEN 'ATIVO' ELSE 'INATIVO' END  AS [SITUAÇÃO CAD. GERAL]
            ,a.CD_CLIENTE                                                AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CPF(CPF)                                       AS CPF
            ,ASSESSOR
            ,CD_BANCO                                                    AS BANCO
            ,AGENCIA                                                     AS [AGÊNCIA]
            ,CONTA
            ,CARGO
            ,PROF_ATIV                                                   AS [PROFISSÃO]
            ,FORMAT(ISNULL(p.PATRIMONIO,0),'f','pt-br')                  AS PATRIMONIO
            ,IN_CONTR_BOLSA  AS [CONTRATO BOLSA]
            ,IN_CONTR_BMF    AS [CONTR. BMF]
            ,IN_CONTR_SOCIAL AS [CONTR. SOCIAL]
            ,IN_CONTR_OPC    AS [CONTR. OPCAO]
            ,IN_CONTR_TER    AS [CONTR. TERMO]
            ,IN_CONTR_TST    AS [CONTR. TST]
            ,IN_CONTR_BTC    AS [CONTR. BTC]
            ,IN_CONTA_MARGEM AS [CONTA MARGEM]
        FROM ST_DADOS_FINANCEIROS_PF a
        LEFT JOIN @PATRIMONIO p ON a.CD_CLIENTE = p.CD_CLIENTE
        WHERE a.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN a.CD_CLIENTE ELSE @CD_CLIENTE END
        ORDER BY 1
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,100000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,100000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
END