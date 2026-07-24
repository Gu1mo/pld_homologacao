CREATE PROCEDURE [dbo].[USP_SCRIPT_TABLE_DDL_FULL]
(
    @SchemaName SYSNAME = NULL,   -- ex: 'dbo' (NULL = todos)
    @TableName  SYSNAME = NULL,   -- ex: 'ST_ALERT_AML_CORRETORA' (NULL = todas)
    @IncludeFK  BIT     = 0       -- 1 para incluir FKs
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CRLF NVARCHAR(2) = CHAR(13) + CHAR(10);
	DECLARE @TABLE_SUFFIX SYSNAME = '_PADRAO';

    SELECT
        s.name  AS schema_name,
        t.name  AS table_name,
        DDL_FULL =
            CAST(
                '/* ===== DDL FULL: ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) + ' ===== */' + @CRLF +
                'CREATE TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) + ' (' + @CRLF +
                cols.cols_definition + @CRLF +
                ');' + @CRLF + @CRLF +
                ISNULL(defs.defaults_script, '') +
                CASE WHEN defs.defaults_script IS NOT NULL AND defs.defaults_script <> '' THEN @CRLF ELSE '' END +
                ISNULL(chks.checks_script, '') +
                CASE WHEN chks.checks_script IS NOT NULL AND chks.checks_script <> '' THEN @CRLF ELSE '' END +
                ISNULL(keys.keys_script, '') +
                CASE WHEN keys.keys_script IS NOT NULL AND keys.keys_script <> '' THEN @CRLF ELSE '' END +
                ISNULL(idxs.indexes_script, '') +
                CASE WHEN idxs.indexes_script IS NOT NULL AND idxs.indexes_script <> '' THEN @CRLF ELSE '' END +
                CASE WHEN @IncludeFK = 1 THEN ISNULL(fks.fk_script, '') ELSE '' END +
                '/* ===== FIM DDL: ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) + ' ===== */' + @CRLF
            AS NVARCHAR(MAX))
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id

    /* 1) COLUNAS */
    OUTER APPLY
    (
        SELECT cols_definition =
            STUFF((
                SELECT
                    ',' + @CRLF + '    ' +
                    CASE
                        WHEN c.is_computed = 1 THEN
                            QUOTENAME(c.name) + ' AS ' + cc.definition
                        ELSE
                            QUOTENAME(c.name) + ' ' +
                            UPPER(ty.name) +
                            CASE
                                WHEN ty.name IN ('varchar','char','varbinary','binary') THEN
                                    '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(10)) END + ')'
                                WHEN ty.name IN ('nvarchar','nchar') THEN
                                    '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(10)) END + ')'
                                WHEN ty.name IN ('decimal','numeric') THEN
                                    '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
                                WHEN ty.name IN ('datetime2','time','datetimeoffset') THEN
                                    '(' + CAST(c.scale AS VARCHAR(10)) + ')'
                                ELSE ''
                            END +
                            CASE
                                WHEN c.collation_name IS NOT NULL AND ty.name IN ('varchar','char','nvarchar','nchar')
                                THEN ' COLLATE ' + c.collation_name
                                ELSE ''
                            END +
                            CASE
                                WHEN ic.object_id IS NOT NULL
                                THEN ' IDENTITY(' + CAST(ic.seed_value AS VARCHAR(30)) + ',' + CAST(ic.increment_value AS VARCHAR(30)) + ')'
                                ELSE ''
                            END +
                            CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END
                    END
                FROM sys.columns c
                JOIN sys.types ty ON ty.user_type_id = c.user_type_id
                LEFT JOIN sys.computed_columns cc
                       ON cc.object_id = c.object_id AND cc.column_id = c.column_id
                LEFT JOIN sys.identity_columns ic
                       ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE c.object_id = t.object_id
                ORDER BY c.column_id
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    ) cols

    /* 2) DEFAULTS */
    OUTER APPLY
    (
        SELECT defaults_script =
            (SELECT
                'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' ADD CONSTRAINT ' + QUOTENAME(dc.name) +
                ' DEFAULT ' + dc.definition +
                ' FOR ' + QUOTENAME(c.name) + ';' + @CRLF
             FROM sys.default_constraints dc
             JOIN sys.columns c
               ON c.object_id = dc.parent_object_id
              AND c.column_id = dc.parent_column_id
             WHERE dc.parent_object_id = t.object_id
             ORDER BY dc.name
             FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
    ) defs

    /* 3) CHECKS */
    OUTER APPLY
    (
        SELECT checks_script =
            (SELECT
                'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' WITH NOCHECK ADD CONSTRAINT ' + QUOTENAME(ck.name) +
                ' CHECK ' + ck.definition + ';' + @CRLF +
                'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' CHECK CONSTRAINT ' + QUOTENAME(ck.name) + ';' + @CRLF
             FROM sys.check_constraints ck
             WHERE ck.parent_object_id = t.object_id
             ORDER BY ck.name
             FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
    ) chks

    /* 4) PK / UNIQUE (constraints) */
    OUTER APPLY
    (
        SELECT keys_script =
            (SELECT
                'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' ADD CONSTRAINT ' + QUOTENAME(kc.name) + ' ' +
                CASE WHEN kc.type = 'PK' THEN 'PRIMARY KEY ' ELSE 'UNIQUE ' END +
                CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
                ' (' +
                STUFF((
                    SELECT ', ' + QUOTENAME(c2.name) + ' ' + CASE WHEN ic2.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
                    FROM sys.index_columns ic2
                    JOIN sys.columns c2
                      ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                    WHERE ic2.object_id = i.object_id
                      AND ic2.index_id  = i.index_id
                      AND ic2.is_included_column = 0
                    ORDER BY ic2.key_ordinal
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                ');' + @CRLF
             FROM sys.key_constraints kc
             JOIN sys.indexes i
               ON i.object_id = kc.parent_object_id
              AND i.index_id  = kc.unique_index_id
             WHERE kc.parent_object_id = t.object_id
             ORDER BY kc.name
             FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
    ) keys

    /* 5) INDEXES (exceto PK/unique constraint) */
    OUTER APPLY
    (
        SELECT indexes_script =
            (SELECT
                'CREATE ' +
                CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
                CASE WHEN i.type = 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END +
                'INDEX ' + QUOTENAME(i.name) +
                ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' (' +
                STUFF((
                    SELECT ', ' + QUOTENAME(c2.name) + ' ' + CASE WHEN ic2.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
                    FROM sys.index_columns ic2
                    JOIN sys.columns c2
                      ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                    WHERE ic2.object_id = i.object_id
                      AND ic2.index_id  = i.index_id
                      AND ic2.is_included_column = 0
                    ORDER BY ic2.key_ordinal
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                ')' +
                CASE
                    WHEN EXISTS (
                        SELECT 1 FROM sys.index_columns ic3
                        WHERE ic3.object_id = i.object_id AND ic3.index_id = i.index_id AND ic3.is_included_column = 1
                    )
                    THEN ' INCLUDE (' +
                         STUFF((
                            SELECT ', ' + QUOTENAME(c3.name)
                            FROM sys.index_columns ic3
                            JOIN sys.columns c3
                              ON c3.object_id = ic3.object_id AND c3.column_id = ic3.column_id
                            WHERE ic3.object_id = i.object_id
                              AND ic3.index_id  = i.index_id
                              AND ic3.is_included_column = 1
                            ORDER BY ic3.index_column_id
                            FOR XML PATH(''), TYPE
                         ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                         ')'
                    ELSE ''
                END +
                CASE WHEN i.has_filter = 1 THEN ' WHERE ' + i.filter_definition ELSE '' END +
                ';' + @CRLF
             FROM sys.indexes i
             WHERE i.object_id = t.object_id
               AND i.is_hypothetical = 0
               AND i.name IS NOT NULL
               AND i.index_id > 0
               AND i.is_primary_key = 0
               AND i.is_unique_constraint = 0
             ORDER BY i.name
             FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
    ) idxs

    /* 6) FK (opcional) */
    OUTER APPLY
    (
        SELECT fk_script =
            (SELECT
                'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name + @TABLE_SUFFIX) +
                ' WITH NOCHECK ADD CONSTRAINT ' + QUOTENAME(fk.name) +
                ' FOREIGN KEY (' +
                STUFF((
                    SELECT ', ' + QUOTENAME(pc.name)
                    FROM sys.foreign_key_columns fkc
                    JOIN sys.columns pc
                      ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
                    WHERE fkc.constraint_object_id = fk.object_id
                    ORDER BY fkc.constraint_column_id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                ') REFERENCES ' + QUOTENAME(rs.name) + '.' + QUOTENAME(rt.name + @TABLE_SUFFIX) +
                ' (' +
                STUFF((
                    SELECT ', ' + QUOTENAME(rc.name)
                    FROM sys.foreign_key_columns fkc
                    JOIN sys.columns rc
                      ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
                    WHERE fkc.constraint_object_id = fk.object_id
                    ORDER BY fkc.constraint_column_id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                ');' + @CRLF
             FROM sys.foreign_keys fk
             JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id
             JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
             WHERE fk.parent_object_id = t.object_id
             ORDER BY fk.name
             FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
    ) fks

    WHERE t.is_ms_shipped = 0
      AND (@SchemaName IS NULL OR s.name = @SchemaName)
      AND (@TableName  IS NULL OR t.name = @TableName)
    ORDER BY t.name;
END