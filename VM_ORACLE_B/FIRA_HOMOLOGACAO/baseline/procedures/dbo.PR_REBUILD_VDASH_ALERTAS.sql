CREATE   PROCEDURE [dbo].[PR_REBUILD_VDASH_ALERTAS]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @union nvarchar(max) = N'';
    DECLARE @sql   nvarchar(max);

    ;WITH A AS (
        SELECT
            NOME_ALERTA = CAST(NOME AS varchar(200)),
            TABELA      = CAST(DESCRICAO AS sysname),
            INCISO_TXT  = CAST(ISNULL(INCISO,'') AS varchar(20)),
            TIPO_TXT    = CAST(ISNULL(Tipo_Alerta,'') AS varchar(60))
        FROM dbo.RelatorioAlertas
        WHERE INDICE = 1  -- (pelo seu print, 1 = ativo)
    )
    SELECT @union = @union +
        CASE WHEN @union = N'' THEN N'' ELSE NCHAR(13)+NCHAR(10)+N'UNION ALL'+NCHAR(13)+NCHAR(10) END +
        N'SELECT '+
        N'CONVERT(date, A.DATA) AS DT_PERIODO, '+
        N'CAST(A.CD_CLIENTE AS int) AS CD_CLIENTE, '+
        N''''+REPLACE(NOME_ALERTA,'''','''''')+N''' AS NOME_ALERTA, '+
        N'COUNT_BIG(1) AS QTD_MES, '+
        N''''+REPLACE(INCISO_TXT,'''','''''')+N''' AS INCISO, '+
        N''''+REPLACE(TIPO_TXT,'''','''''')+N''' AS Tipo_alerta '+
        N'FROM dbo.'+QUOTENAME(TABELA)+N' A '+
        N'GROUP BY CONVERT(date, A.DATA), CAST(A.CD_CLIENTE AS int)'
    FROM A;

    IF @union = N''
    BEGIN
        -- cria a view vazia (evita quebrar dashboard se não houver alertas ativos)
        SET @sql = N'
CREATE OR ALTER VIEW dbo.VDASH_ALERTAS
AS
SELECT
    CAST(NULL AS date)         AS DT_PERIODO,
    CAST(NULL AS int)          AS CD_CLIENTE,
    CAST(NULL AS varchar(200)) AS NM_CLIENTE,
    CAST(NULL AS varchar(30))  AS CD_CPFCGC,
    CAST(NULL AS varchar(200)) AS NM_ALERTA,
    CAST(0 AS bigint)          AS QTD_ALERTAS_PERIODO,
    CAST(NULL AS varchar(20))  AS INCISO,
    CAST(0 AS float)           AS AJUSTE,
    CAST(NULL AS varchar(60))  AS Tipo_alerta
WHERE 1=0;';
        EXEC (@sql);
        RETURN;
    END

    SET @sql = N'
CREATE OR ALTER VIEW dbo.VDASH_ALERTAS
AS
SELECT
    XX.DT_PERIODO,
    XX.CD_CLIENTE,
    B.NM_CLIENTE,
    B.CD_CPFCGC,
    XX.NOME_ALERTA AS NM_ALERTA,
    SUM(XX.QTD_ALERTAS_PERIODO) AS QTD_ALERTAS_PERIODO,
    XX.INCISO,
    ISNULL(MAX(C.[VALUE]),0) AS AJUSTE,
    XX.Tipo_alerta
FROM (
    SELECT
        X.DT_PERIODO,
        X.CD_CLIENTE,
        X.NOME_ALERTA,
        COUNT(X.QTD_MES) AS QTD_ALERTAS_PERIODO,
        X.INCISO,
        X.Tipo_alerta
    FROM (
        '+@union+N'
    ) X
    GROUP BY
        X.DT_PERIODO, X.CD_CLIENTE, X.NOME_ALERTA, X.INCISO, X.Tipo_alerta
) XX
LEFT JOIN (SELECT DISTINCT CD_CLIENTE, NM_CLIENTE, CD_CPFCGC FROM V_CLIENTE_TODOS) B
    ON XX.CD_CLIENTE = B.CD_CLIENTE
LEFT JOIN SCORE C
    ON XX.NOME_ALERTA = C.NAME
GROUP BY
    XX.DT_PERIODO, XX.CD_CLIENTE, XX.NOME_ALERTA, XX.INCISO,
    B.NM_CLIENTE, B.CD_CPFCGC, XX.Tipo_alerta;
';

    EXEC (@sql);
END