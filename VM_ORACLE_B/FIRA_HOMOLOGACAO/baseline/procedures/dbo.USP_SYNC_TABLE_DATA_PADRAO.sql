CREATE PROCEDURE dbo.USP_SYNC_TABLE_DATA_PADRAO
(
      @src_schema SYSNAME
    , @src_table  SYSNAME
    , @dst_schema SYSNAME
    , @dst_table  SYSNAME
    , @execute    BIT = 1      -- 1 executa | 0 dry-run (só imprime)
    , @allow_delete BIT = 1    -- 1 apaga do destino o que não existe no PADRAO
    , @copy_identity BIT = 1   -- 1 copia coluna IDENTITY (mantém IDs iguais)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @src NVARCHAR(300) = QUOTENAME(@src_schema) + '.' + QUOTENAME(@src_table);
    DECLARE @dst NVARCHAR(300) = QUOTENAME(@dst_schema) + '.' + QUOTENAME(@dst_table);

    IF OBJECT_ID(@src) IS NULL THROW 50001, 'Tabela PADRAO (src) não existe.', 1;
    IF OBJECT_ID(@dst) IS NULL THROW 50002, 'Tabela destino (dst) não existe.', 1;

    DECLARE @src_obj INT = OBJECT_ID(@src);
    DECLARE @dst_obj INT = OBJECT_ID(@dst);

    --------------------------------------------------------------------
    -- 1) Chave (PK preferencial, senão UNIQUE)
    --------------------------------------------------------------------
    DECLARE @key_index_id INT = NULL;

    SELECT TOP (1) @key_index_id = kc.unique_index_id
    FROM sys.key_constraints kc
    WHERE kc.parent_object_id = @dst_obj
      AND kc.type = 'PK'
    ORDER BY kc.name;

    IF @key_index_id IS NULL
    BEGIN
        SELECT TOP (1) @key_index_id = i.index_id
        FROM sys.indexes i
        WHERE i.object_id = @dst_obj
          AND i.is_unique = 1
          AND i.has_filter = 0
          AND i.is_hypothetical = 0
          AND i.index_id > 0
        ORDER BY CASE WHEN i.is_unique_constraint = 1 THEN 0 ELSE 1 END, i.index_id;
    END

    IF @key_index_id IS NULL
        THROW 50003, 'Tabela destino não possui PK nem UNIQUE (sem filtro). Não dá para sincronizar dados com segurança.', 1;

    DECLARE @join NVARCHAR(MAX) = N'';
    SELECT @join = STUFF((
        SELECT N' AND T.' + QUOTENAME(c.name) + N' = S.' + QUOTENAME(c.name)
        FROM sys.index_columns ic
        JOIN sys.columns c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = @dst_obj
          AND ic.index_id  = @key_index_id
          AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'), 1, 5, N'');

    --------------------------------------------------------------------
    -- 2) Colunas comuns (src ∩ dst)
    --------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#cols') IS NOT NULL DROP TABLE #cols;
    CREATE TABLE #cols(col SYSNAME NOT NULL, is_key BIT NOT NULL);

    ;WITH src_cols AS (
        SELECT c.name, c.is_identity, c.is_computed, t.name AS type_name
        FROM sys.columns c
        JOIN sys.types t ON t.user_type_id = c.user_type_id
        WHERE c.object_id = @src_obj
    ),
    dst_cols AS (
        SELECT c.name, c.is_identity, c.is_computed, t.name AS type_name
        FROM sys.columns c
        JOIN sys.types t ON t.user_type_id = c.user_type_id
        WHERE c.object_id = @dst_obj
    ),
    key_cols AS (
        SELECT c.name
        FROM sys.index_columns ic
        JOIN sys.columns c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = @dst_obj
          AND ic.index_id  = @key_index_id
          AND ic.is_included_column = 0
    )
    INSERT #cols(col, is_key)
    SELECT
        d.name,
        CASE WHEN EXISTS (SELECT 1 FROM key_cols k WHERE k.name = d.name) THEN 1 ELSE 0 END
    FROM dst_cols d
    JOIN src_cols s ON s.name = d.name
    WHERE d.is_computed = 0 AND s.is_computed = 0
      AND d.type_name NOT IN ('timestamp','rowversion')
      AND s.type_name NOT IN ('timestamp','rowversion')
      AND (
            @copy_identity = 1
            OR (d.is_identity = 0 AND s.is_identity = 0)
          );

    --------------------------------------------------------------------
    -- 3) MERGE: UPDATE / INSERT / DELETE
    --------------------------------------------------------------------
    DECLARE @setlist NVARCHAR(MAX) = N'';
    SELECT @setlist = STUFF((
        SELECT N', T.' + QUOTENAME(col) + N' = S.' + QUOTENAME(col)
        FROM #cols
        WHERE is_key = 0
          AND NOT EXISTS (
              SELECT 1
              FROM sys.columns c
              WHERE c.object_id = @dst_obj AND c.name = #cols.col AND c.is_identity = 1
          )
        ORDER BY col
        FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'), 1, 2, N'');

    DECLARE @insert_cols NVARCHAR(MAX) = N'';
    DECLARE @insert_vals NVARCHAR(MAX) = N'';

    SELECT
        @insert_cols = STUFF((
            SELECT N', ' + QUOTENAME(col)
            FROM #cols
            ORDER BY col
            FOR XML PATH(''), TYPE
        ).value('.','nvarchar(max)'), 1, 2, N''),
        @insert_vals = STUFF((
            SELECT N', S.' + QUOTENAME(col)
            FROM #cols
            ORDER BY col
            FOR XML PATH(''), TYPE
        ).value('.','nvarchar(max)'), 1, 2, N'');

    DECLARE @diff NVARCHAR(MAX) = N'';
    SELECT @diff = STUFF((
        SELECT N' OR (ISNULL(CONVERT(nvarchar(max),T.' + QUOTENAME(col) + N'),''∅'') <> ISNULL(CONVERT(nvarchar(max),S.' + QUOTENAME(col) + N'),''∅''))'
        FROM #cols
        WHERE is_key = 0
          AND NOT EXISTS (
              SELECT 1
              FROM sys.columns c
              WHERE c.object_id = @dst_obj AND c.name = #cols.col AND c.is_identity = 1
          )
        ORDER BY col
        FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'), 1, 4, N'');

    DECLARE @sql NVARCHAR(MAX) =
N'MERGE ' + @dst + N' AS T
USING ' + @src + N' AS S
ON ' + @join + N'
' + CASE WHEN @setlist <> '' THEN
N'WHEN MATCHED AND (' + @diff + N')
    THEN UPDATE SET ' + @setlist + N'
' ELSE N'' END +
N'WHEN NOT MATCHED BY TARGET
    THEN INSERT (' + @insert_cols + N') VALUES (' + @insert_vals + N')
' + CASE WHEN @allow_delete = 1 THEN
N'WHEN NOT MATCHED BY SOURCE
    THEN DELETE
' ELSE N'' END +
N';';

    -- se for copiar identity, precisa ligar IDENTITY_INSERT (somente se houver identity no destino)
    DECLARE @has_identity BIT = 0;
    SELECT TOP (1) @has_identity = 1
    FROM sys.columns c
    WHERE c.object_id = @dst_obj AND c.is_identity = 1;

    IF @copy_identity = 1 AND @has_identity = 1
    BEGIN
        SET @sql =
            N'SET IDENTITY_INSERT ' + @dst + N' ON;' + CHAR(13) + CHAR(10) +
            @sql + CHAR(13) + CHAR(10) +
            N'SET IDENTITY_INSERT ' + @dst + N' OFF;';
    END

    IF @execute = 0
    BEGIN
        SELECT @sql AS merge_sql;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;
        EXEC sys.sp_executesql @sql;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END