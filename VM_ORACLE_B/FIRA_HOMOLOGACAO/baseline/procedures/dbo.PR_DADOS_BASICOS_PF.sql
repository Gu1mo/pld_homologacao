CREATE PROCEDURE [dbo].[PR_DADOS_BASICOS_PF]
    @CD_ANO         VARCHAR(4)  = NULL,
    @DS_MES         VARCHAR(20) = NULL,
    @CD_CLIENTE     VARCHAR(10) = NULL,
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

    DECLARE @ALERTAS_PERIODO TABLE (CD_CLIENTE VARCHAR(10) PRIMARY KEY);

    IF ISNULL(@DS_MES, '') <> '' AND ISNULL(@CD_ANO, '') <> ''
        INSERT INTO @ALERTAS_PERIODO (CD_CLIENTE)
        SELECT DISTINCT CAST(K.[Cód. Cliente] AS VARCHAR(10))
        FROM ST_RELATORIO_PAINEL_ALERTAS_CVM (NOLOCK) K
        WHERE LTRIM(RTRIM(LEFT(K.REFERENCIA, CHARINDEX('/', K.REFERENCIA) - 1)))                          = @DS_MES
          AND LTRIM(RTRIM(SUBSTRING(K.REFERENCIA, CHARINDEX('/', K.REFERENCIA) + 1, LEN(K.REFERENCIA)))) = @CD_ANO
          AND K.[PF / PJ] = 'PF';

    IF ISNULL(@DS_MES, '') <> '' AND ISNULL(@CD_ANO, '') <> ''
    BEGIN
        ;WITH DADOS_DEDUP AS (
            SELECT A.*, B.[RISCO],
                   ROW_NUMBER() OVER (PARTITION BY A.CD_CLIENTE ORDER BY A.DT_ATUALIZ DESC) AS RN
            FROM ST_DADOS_BASICOS_PF A
            INNER JOIN @ALERTAS_PERIODO AP ON CAST(A.CD_CLIENTE AS VARCHAR(10)) = AP.CD_CLIENTE
            LEFT  JOIN ST_PROFISSAO_RISCO B ON A.DS_ATIV = B.PROFISSAO
            WHERE A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE, '') = '' THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
        )
        SELECT
             CASE WHEN IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END AS [SITUAÇÃO MOD. BOLSA]
            ,TP_SITUAC                                                   AS [SITUAÇÃO CAD. GERAL]
            ,CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CPF(CD_CPFCGC)                                AS [CPF]
            ,FORMAT(DT_CRIACAO,  'd', 'pt-br')                          AS [DATA DE CRIAÇÃO]
            ,FORMAT(DT_ATUALIZ,  'd', 'pt-br')                          AS [DATA DE ATUALIZAÇÃO]
            ,FORMAT(DT_VALIDADE, 'd', 'pt-br')                          AS [DATA DE VALIDADE]
            ,CONCAT(ISNULL(NM_LOGRADOURO,''),', ',ISNULL(NR_PREDIO,''),' - ',ISNULL(NM_COMP_ENDE,'')) AS [ENDEREÇO]
            ,NM_BAIRRO                                                   AS [BAIRRO]
            ,NM_CIDADE                                                   AS [CIDADE]
            ,CD_CEP                                                      AS CEP
            ,SG_ESTADO                                                   AS [ESTADO]
            ,SG_PAIS                                                     AS [PAÍS]
            ,CASE IN_POLITICO_EXP WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [PEP]
            ,DS_TIPO_CLIENTE                                             AS [TIPO DE INVESTIDOR]
            ,NR_TELEFONE                                                 AS TELEFONE
            ,NM_E_MAIL                                                   AS [E-MAIL]
            ,DS_ATIV                                                     AS [PROFISSÃO]
            ,ISNULL([RISCO], 'NÃO CLASSIFICADO')                        AS [PROFISSÃO DE RISCO]
            ,DS_CARGO                                                    AS [CARGO]
            ,FORMAT(DT_NASC_FUND, 'd', 'pt-br')                        AS [DATA DE NASCIMENTO]
            ,NM_EMIT_ORDEM                                               AS [CLIENTE EMITENTE]
            ,CASE IN_PESS_VINC WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [PESSOA VINCULADA]
            ,CD_CPFCGC_EMIT                                              AS [CPF DO EMITENTE]
            ,NM_GRUPO                                                    AS [NOME DO GRUPO]
            ,CD_ASSESSOR                                                 AS [CÓD. ASSESSOR]
            ,NM_ASSESSOR                                                 AS [NOME ASSESSOR]
            ,DS_NACION                                                   AS [NACIONALIDADE]
            ,NM_MAE                                                      AS [NOME DA MÃE]
            ,NM_PAI                                                      AS [NOME DO PAI]
            ,NM_CONJUGE                                                  AS [NOME DO CÔNJUGE]
            ,CASE IN_PRINCIPAL WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [EMISSOR PRINCIPAL]
        FROM DADOS_DEDUP
        WHERE RN = 1
        ORDER BY CD_CLIENTE
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,20000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,20000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        SELECT DISTINCT
             CASE WHEN A.IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END AS [SITUAÇÃO MOD. BOLSA]
            ,A.TP_SITUAC                                                   AS [SITUAÇÃO CAD. GERAL]
            ,A.CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,A.NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,dbo.FORMATAR_CPF(A.CD_CPFCGC)                                AS [CPF]
            ,FORMAT(A.DT_CRIACAO,  'd', 'pt-br')                          AS [DATA DE CRIAÇÃO]
            ,FORMAT(A.DT_ATUALIZ,  'd', 'pt-br')                          AS [DATA DE ATUALIZAÇÃO]
            ,FORMAT(A.DT_VALIDADE, 'd', 'pt-br')                          AS [DATA DE VALIDADE]
            ,CONCAT(ISNULL(MAX(NM_LOGRADOURO),''),', ',ISNULL(MAX(NR_PREDIO),''),' - ',ISNULL(MAX(NM_COMP_ENDE),'')) AS [ENDEREÇO]
            ,MAX(NM_BAIRRO)                                                AS [BAIRRO]
            ,MAX(NM_CIDADE)                                                AS [CIDADE]
            ,MAX(CD_CEP)                                                   AS CEP
            ,MAX(SG_ESTADO)                                                AS [ESTADO]
            ,A.SG_PAIS                                                     AS [PAÍS]
            ,CASE A.IN_POLITICO_EXP WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [PEP]
            ,A.DS_TIPO_CLIENTE                                             AS [TIPO DE INVESTIDOR]
            ,A.NR_TELEFONE                                                 AS TELEFONE
            ,MAX(NM_E_MAIL)                                                AS [E-MAIL]
            ,A.DS_ATIV                                                     AS [PROFISSÃO]
            ,ISNULL(B.[RISCO], 'NÃO CLASSIFICADO')                        AS [PROFISSÃO DE RISCO]
            ,A.DS_CARGO                                                    AS [CARGO]
            ,FORMAT(A.DT_NASC_FUND, 'd', 'pt-br')                        AS [DATA DE NASCIMENTO]
            ,A.NM_EMIT_ORDEM                                               AS [CLIENTE EMITENTE]
            ,CASE A.IN_PESS_VINC WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [PESSOA VINCULADA]
            ,A.CD_CPFCGC_EMIT                                              AS [CPF DO EMITENTE]
            ,A.NM_GRUPO                                                    AS [NOME DO GRUPO]
            ,A.CD_ASSESSOR                                                 AS [CÓD. ASSESSOR]
            ,A.NM_ASSESSOR                                                 AS [NOME ASSESSOR]
            ,A.DS_NACION                                                   AS [NACIONALIDADE]
            ,A.NM_MAE                                                      AS [NOME DA MÃE]
            ,A.NM_PAI                                                      AS [NOME DO PAI]
            ,A.NM_CONJUGE                                                  AS [NOME DO CÔNJUGE]
            ,CASE A.IN_PRINCIPAL WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [EMISSOR PRINCIPAL]
        FROM ST_DADOS_BASICOS_PF A
        LEFT JOIN ST_PROFISSAO_RISCO B ON A.DS_ATIV = B.PROFISSAO
        WHERE A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
        GROUP BY
             A.IN_SITUAC, A.TP_SITUAC, A.CD_CPFCGC, A.NM_CLIENTE, A.CD_CLIENTE
            ,FORMAT(A.DT_CRIACAO,'d','pt-br'), A.DS_ATIV, B.[RISCO], A.DS_CARGO
            ,FORMAT(A.DT_NASC_FUND,'d','pt-br'), A.NM_EMIT_ORDEM, A.SG_PAIS
            ,A.DS_NACION, A.IN_POLITICO_EXP, A.IN_PESS_VINC, A.DS_TIPO_CLIENTE
            ,A.CD_CPFCGC_EMIT, FORMAT(A.DT_VALIDADE,'d','pt-br'), A.NM_MAE
            ,A.NM_PAI, A.NM_CONJUGE, A.NR_TELEFONE, FORMAT(A.DT_ATUALIZ,'d','pt-br')
            ,A.NM_GRUPO, A.CD_ASSESSOR, A.NM_ASSESSOR, A.IN_PRINCIPAL, A.NM_COMPL_NOME
        ORDER BY A.CD_CLIENTE
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,20000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,20000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
END