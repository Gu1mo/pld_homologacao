ALTER PROCEDURE [dbo].[PR_DADOS_BASICOS_PJ]
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

    DECLARE @ALERTAS_PERIODO TABLE (CD_CLIENTE VARCHAR(10) PRIMARY KEY);

    IF ISNULL(@DS_MES, '') <> '' AND ISNULL(@CD_ANO, '') <> ''
        INSERT INTO @ALERTAS_PERIODO (CD_CLIENTE)
        SELECT DISTINCT CAST(K.[Cód. Cliente] AS VARCHAR(10))
        FROM ST_RELATORIO_PAINEL_ALERTAS_CVM (NOLOCK) K
        WHERE LTRIM(RTRIM(LEFT(K.REFERENCIA, CHARINDEX('/', K.REFERENCIA) - 1)))                          = @DS_MES
          AND LTRIM(RTRIM(SUBSTRING(K.REFERENCIA, CHARINDEX('/', K.REFERENCIA) + 1, LEN(K.REFERENCIA)))) = @CD_ANO
          AND K.[PF / PJ] = 'PJ';

    IF ISNULL(@DS_MES, '') <> '' AND ISNULL(@CD_ANO, '') <> ''
    BEGIN
        ;WITH DADOS_DEDUP AS (
            SELECT A.*, B.[RISCO],
                   ROW_NUMBER() OVER (PARTITION BY A.CD_CLIENTE ORDER BY A.DT_ATUALIZ DESC) AS RN
            FROM ST_DADOS_BASICOS_PJ A
            INNER JOIN @ALERTAS_PERIODO AP ON CAST(A.CD_CLIENTE AS VARCHAR(10)) = AP.CD_CLIENTE
            LEFT  JOIN ST_PROFISSAO_RISCO B ON A.DS_TIPO_CLIENTE = B.PROFISSAO
            WHERE A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
        )
        SELECT
             CASE WHEN IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END AS [SITUAÇÃO MOD. BOLSA]
            ,TP_SITUAC                                                   AS [SITUAÇÃO CAD. GERAL]
            ,CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,CD_CPFCGC),LEN(CD_CPFCGC)+1,15),1,3)+'.'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,CD_CPFCGC),LEN(CD_CPFCGC)+1,15),4,3)+'.'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,CD_CPFCGC),LEN(CD_CPFCGC)+1,15),7,3)+'/'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,CD_CPFCGC),LEN(CD_CPFCGC)+1,15),10,4)+'-'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,CD_CPFCGC),LEN(CD_CPFCGC)+1,15),14,2) AS CNPJ
            ,CONVERT(VARCHAR, DT_CRIACAO, 103)                          AS [DATA DE CRIAÇÃO]
            ,FORMAT(DT_ATUALIZ,  'd', 'pt-br')                         AS [DATA DE ATUALIZAÇÃO]
            ,FORMAT(DT_VALIDADE, 'd', 'pt-br')                         AS [DATA DE VALIDADE]
            ,CONCAT(ISNULL(NM_LOGRADOURO,''),', ',ISNULL(NR_PREDIO,''),' - ',ISNULL(NM_COMP_ENDE,'')) AS [ENDEREÇO]
            ,NM_BAIRRO                                                  AS BAIRRO
            ,NM_CIDADE                                                  AS CIDADE
            ,CD_CEP                                                     AS CEP
            ,SG_ESTADO                                                  AS ESTADO
            ,SG_PAIS                                                    AS [PAÍS]
            ,CASE IN_POLITICO_EXP WHEN 'S' THEN 'SIM' WHEN 'N' THEN 'NÃO' ELSE '' END AS [PEP]
            ,CASE WHEN IN_PESS_VINC='S' THEN 'SIM' ELSE 'NÃO' END     AS [PESSOA VINCULADA]
            ,ISNULL(DS_TIPO_CLIENTE,'OUTROS')                           AS [TIPO DE INVESTIDOR]
            ,ISNULL([RISCO],'NÃO CLASSIFICADO')                        AS [PROFISSÃO DE RISCO]
            ,ISNULL(CAST(NR_TELEFONE AS VARCHAR),'-')                   AS TELEFONE
            ,ISNULL(NM_E_MAIL,'-')                                      AS [E-MAIL]
            ,(SELECT COUNT(DISTINCT XX.NM_EMIT_ORDEM) FROM TSCEMITORDEM XX WHERE XX.CD_CPFCGC = CD_CPFCGC) AS [NR EMITENTES]
            ,NM_EMIT_ORDEM                                              AS [NOME DO EMITENTE]
            ,ISNULL(NM_GRUPO,'-')                                       AS [NOME DO GRUPO]
            ,CD_ASSESSOR                                                AS [CÓD. ASSESSOR]
            ,NM_ASSESSOR                                                AS [NOME DO ASSESSOR]
            ,FORMAT(DT_ULT_OPER,'d','pt-br')                           AS [DATA ULT. OPERAÇÃO]
			, 9999 [Códido da Corretora]
        FROM DADOS_DEDUP
        WHERE RN = 1
        ORDER BY CD_CLIENTE
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,100000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,100000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        SELECT DISTINCT
             CASE WHEN A.IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END AS [SITUAÇÃO MOD. BOLSA]
            ,A.TP_SITUAC                                                   AS [SITUAÇÃO CAD. GERAL]
            ,A.CD_CLIENTE                                                  AS [CÓD. CLIENTE]
            ,A.NM_CLIENTE                                                  AS [NOME DO CLIENTE]
            ,SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,A.CD_CPFCGC),LEN(A.CD_CPFCGC)+1,15),1,3)+'.'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,A.CD_CPFCGC),LEN(A.CD_CPFCGC)+1,15),4,3)+'.'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,A.CD_CPFCGC),LEN(A.CD_CPFCGC)+1,15),7,3)+'/'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,A.CD_CPFCGC),LEN(A.CD_CPFCGC)+1,15),10,4)+'-'+
             SUBSTRING(SUBSTRING('000000000000000'+CONVERT(VARCHAR,A.CD_CPFCGC),LEN(A.CD_CPFCGC)+1,15),14,2) AS CNPJ
            ,CONVERT(VARCHAR, A.DT_CRIACAO, 103)                          AS [DATA DE CRIAÇÃO]
            ,FORMAT(A.DT_ATUALIZ,  'd', 'pt-br')                         AS [DATA DE ATUALIZAÇÃO]
            ,FORMAT(A.DT_VALIDADE, 'd', 'pt-br')                         AS [DATA DE VALIDADE]
            ,CONCAT(ISNULL(MAX(NM_LOGRADOURO),''),', ',ISNULL(MAX(NR_PREDIO),''),' - ',ISNULL(MAX(NM_COMP_ENDE),'')) AS [ENDEREÇO]
            ,MAX(NM_BAIRRO)                                               AS BAIRRO
            ,MAX(NM_CIDADE)                                               AS CIDADE
            ,MAX(CD_CEP)                                                  AS CEP
            ,MAX(SG_ESTADO)                                               AS ESTADO
            ,A.SG_PAIS                                                    AS [PAÍS]
            ,CASE WHEN A.IN_POLITICO_EXP='S' THEN 'SIM' WHEN A.IN_POLITICO_EXP='N' THEN 'NÃO' ELSE '' END AS [PEP]
            ,CASE WHEN A.IN_PESS_VINC='S' THEN 'SIM' ELSE 'NÃO' END     AS [PESSOA VINCULADA]
            ,ISNULL(A.DS_TIPO_CLIENTE,'OUTROS')                           AS [TIPO DE INVESTIDOR]
            ,ISNULL(MAX(B.[RISCO]),'NÃO CLASSIFICADO')                   AS [PROFISSÃO DE RISCO]
            ,ISNULL(CAST(MAX(A.NR_TELEFONE) AS VARCHAR),'-')              AS TELEFONE
            ,ISNULL(A.NM_E_MAIL,'-')                                      AS [E-MAIL]
            ,(SELECT COUNT(DISTINCT XX.NM_EMIT_ORDEM) FROM TSCEMITORDEM XX WHERE XX.CD_CPFCGC = A.CD_CPFCGC) AS [NR EMITENTES]
            ,A.NM_EMIT_ORDEM                                              AS [NOME DO EMITENTE]
            ,ISNULL(A.NM_GRUPO,'-')                                       AS [NOME DO GRUPO]
            ,A.CD_ASSESSOR                                                AS [CÓD. ASSESSOR]
            ,A.NM_ASSESSOR                                                AS [NOME DO ASSESSOR]
            ,FORMAT(A.DT_ULT_OPER,'d','pt-br')                           AS [DATA ULT. OPERAÇÃO]
			, 9999 [Códido da Corretora]
        FROM ST_DADOS_BASICOS_PJ A
        LEFT JOIN ST_PROFISSAO_RISCO B ON A.DS_TIPO_CLIENTE = B.PROFISSAO
        WHERE A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
        GROUP BY
             CASE WHEN A.IN_SITUAC='A' THEN 'ATIVO' ELSE 'INATIVO' END
            ,A.TP_SITUAC, A.CD_CPFCGC, A.CD_CLIENTE, A.NM_CLIENTE
            ,A.DT_VALIDADE, A.DT_ATUALIZ, A.SG_PAIS, ISNULL(A.NM_E_MAIL,'-'), A.DT_CRIACAO
            ,A.IN_POLITICO_EXP
            ,CASE WHEN A.IN_PESS_VINC='S' THEN 'SIM' ELSE 'NÃO' END
            ,ISNULL(A.DS_TIPO_CLIENTE,'OUTROS')
            ,A.NM_EMIT_ORDEM, FORMAT(A.DT_ULT_OPER,'d','pt-br')
            ,ISNULL(A.NM_GRUPO,'-'), A.CD_ASSESSOR, A.NM_ASSESSOR
        ORDER BY A.CD_CLIENTE
        OFFSET (ISNULL(@PAGINA,1)-1) * ISNULL(@QTDPORPAGINA,100000000) ROWS
        FETCH NEXT ISNULL(@QTDPORPAGINA,100000000) ROWS ONLY
        OPTION (RECOMPILE);
    END
END
