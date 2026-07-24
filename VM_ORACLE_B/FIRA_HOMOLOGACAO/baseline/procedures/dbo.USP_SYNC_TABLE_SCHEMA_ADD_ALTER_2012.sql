CREATE   PROCEDURE [dbo].[USP_SYNC_TABLE_SCHEMA_ADD_ALTER_2012]
(
      @schema_name        sysname = N'dbo'
    , @base_table         sysname
    , @suffix_padrao      sysname = N'_PADRAO'
    , @execute            bit = 1
    , @allow_drop         bit = 1
    , @apply_rename_map   bit = 1
    , @shrink_strings     bit = 1   -- 0 = não encolhe varchar/nvarchar/char/nchar
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @src_table sysname = @base_table + @suffix_padrao,
        @dst_table sysname = @base_table,
        @src_full  nvarchar(400),
        @dst_full  nvarchar(400),
        @sql       nvarchar(max);

    SET @src_full = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@src_table);
    SET @dst_full = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@dst_table);

    /* cria destino se não existir */
    IF OBJECT_ID(@dst_full, 'U') IS NULL
    BEGIN
        SET @sql = N'SELECT TOP (0) * INTO ' + @dst_full + N' FROM ' + @src_full + N';';
        IF @execute = 1 EXEC sys.sp_executesql @sql;
        ELSE PRINT @sql;
    END

    /* renomeações */
    IF @apply_rename_map = 1 AND OBJECT_ID('dbo.SCHEMA_SYNC_RENAME_MAP','U') IS NOT NULL
    BEGIN
        DECLARE @old sysname, @new sysname;

        DECLARE cur_rename CURSOR FAST_FORWARD FOR
            SELECT old_col, new_col
            FROM dbo.SCHEMA_SYNC_RENAME_MAP
            WHERE base_table = @dst_table;

        OPEN cur_rename;
        FETCH NEXT FROM cur_rename INTO @old, @new;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF COL_LENGTH(@dst_full, @old) IS NOT NULL
               AND COL_LENGTH(@dst_full, @new) IS NULL
            BEGIN
                SET @sql = N'EXEC sys.sp_rename N''' + @schema_name + N'.' + @dst_table + N'.' + @old
                         + N''', N''' + REPLACE(@new,'''','''''') + N''', ''COLUMN'';';
                IF @execute = 1 EXEC sys.sp_executesql @sql; ELSE PRINT @sql;
            END

            FETCH NEXT FROM cur_rename INTO @old, @new;
        END

        CLOSE cur_rename;
        DEALLOCATE cur_rename;
    END

    /* metadata PADRAO */
    IF OBJECT_ID('tempdb..#SrcCols') IS NOT NULL DROP TABLE #SrcCols;

    SELECT
        c.name AS col_name,
        t.name AS type_name,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.collation_name
    INTO #SrcCols
    FROM sys.columns c
    JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@src_full);

    DECLARE
        @col sysname,
        @src_type sysname,
        @src_len int,
        @src_prec int,
        @src_scale int,
        @src_null bit,
        @src_coll sysname;

    DECLARE cur_src CURSOR FAST_FORWARD FOR
        SELECT col_name, type_name, max_length, precision, scale, is_nullable, collation_name
        FROM #SrcCols
        ORDER BY col_name;

    OPEN cur_src;
    FETCH NEXT FROM cur_src INTO @col, @src_type, @src_len, @src_prec, @src_scale, @src_null, @src_coll;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        /* monta type_def */
        DECLARE @type_def nvarchar(300) = @src_type;
        DECLARE @coll_def nvarchar(200) = N'';
        DECLARE @null_def nvarchar(20)  = CASE WHEN @src_null = 1 THEN N'NULL' ELSE N'NOT NULL' END;

        IF @src_type IN ('varchar','char','varbinary','binary','nvarchar','nchar')
        BEGIN
            DECLARE @len int =
                CASE
                    WHEN @src_len = -1 THEN -1
                    WHEN @src_type IN ('nvarchar','nchar') THEN @src_len/2
                    ELSE @src_len
                END;

            SET @type_def = @src_type + N'(' + CASE WHEN @len = -1 THEN N'MAX' ELSE CONVERT(nvarchar(10), @len) END + N')';
        END
        ELSE IF @src_type IN ('decimal','numeric')
            SET @type_def = @src_type + N'(' + CONVERT(nvarchar(10), CASE WHEN @src_prec < 1 THEN 18 ELSE @src_prec END)
                         + N',' + CONVERT(nvarchar(10), CASE WHEN @src_scale < 0 THEN 0 ELSE @src_scale END) + N')';
        ELSE IF @src_type IN ('datetime2','time','datetimeoffset')
            SET @type_def = @src_type + N'(' + CONVERT(nvarchar(10), CASE WHEN @src_scale < 0 THEN 7 ELSE @src_scale END) + N')';

        IF @src_coll IS NOT NULL AND @src_type IN ('varchar','char','nvarchar','nchar','text','ntext')
            SET @coll_def = N' COLLATE ' + @src_coll;

        /* EXISTE no destino? */
        IF COL_LENGTH(@dst_full, @col) IS NULL
        BEGIN
            SET @sql = N'ALTER TABLE ' + @dst_full + N' ADD ' + QUOTENAME(@col) + N' ' + @type_def + @coll_def + N' ' + @null_def + N';';
            IF @execute = 1 EXEC sys.sp_executesql @sql; ELSE PRINT @sql;
        END
        ELSE
        BEGIN
            /* metadados do destino */
            DECLARE
                @dst_type sysname,
                @dst_len int,
                @dst_prec int,
                @dst_scale int,
                @dst_null bit,
                @dst_coll sysname;

            SELECT
                @dst_type = t.name,
                @dst_len  = c.max_length,
                @dst_prec = c.precision,
                @dst_scale= c.scale,
                @dst_null = c.is_nullable,
                @dst_coll = c.collation_name
            FROM sys.columns c
            JOIN sys.types t ON t.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(@dst_full)
              AND c.name = @col;

            DECLARE @need bit = 0;

            IF @dst_type <> @src_type SET @need = 1;
            IF ISNULL(@dst_prec,-999)<> ISNULL(@src_prec,-999) SET @need = 1;
            IF ISNULL(@dst_scale,-999)<> ISNULL(@src_scale,-999) SET @need = 1;
            IF ISNULL(@dst_null,0) <> ISNULL(@src_null,0) SET @need = 1;

            IF @src_coll IS NOT NULL AND @src_type IN ('varchar','char','nvarchar','nchar','text','ntext')
               AND ISNULL(@dst_coll,'') <> ISNULL(@src_coll,'')
               SET @need = 1;

            /* regra de comprimento: NÃO encolher strings automaticamente */
            DECLARE @src_char_len int = NULL, @dst_char_len int = NULL;

            IF @src_type IN ('varchar','nvarchar','char','nchar') AND @dst_type = @src_type
            BEGIN
                SET @src_char_len =
                    CASE WHEN @src_len = -1 THEN -1
                         WHEN @src_type IN ('nvarchar','nchar') THEN @src_len/2
                         ELSE @src_len END;

                SET @dst_char_len =
                    CASE WHEN @dst_len = -1 THEN -1
                         WHEN @dst_type IN ('nvarchar','nchar') THEN @dst_len/2
                         ELSE @dst_len END;

                IF ISNULL(@dst_char_len,-999) <> ISNULL(@src_char_len,-999)
                    SET @need = 1;

                IF @shrink_strings = 0 AND @src_char_len <> -1
                   AND ( @dst_char_len = -1 OR @dst_char_len > @src_char_len )
                BEGIN
                    PRINT CONCAT('SKIP_SHRINK: ', @dst_full, '.', @col, ' destino maior que padrao.');
                    SET @need = 0;
                END
            END
            ELSE
            BEGIN
                IF ISNULL(@dst_len,-999) <> ISNULL(@src_len,-999) SET @need = 1;
            END

            /* se for mudar para NOT NULL, checar se há NULLs */
            IF @need = 1 AND @src_null = 0
            BEGIN
                DECLARE @has_null int = 0;
                SET @sql = N'SELECT @has_null = COUNT(*) FROM ' + @dst_full + N' WITH (NOLOCK) WHERE ' + QUOTENAME(@col) + N' IS NULL;';
                EXEC sys.sp_executesql @sql, N'@has_null int OUTPUT', @has_null = @has_null OUTPUT;

                IF @has_null > 0
                BEGIN
                    PRINT CONCAT('SKIP_NOT_NULL: ', @dst_full, '.', @col, ' possui ', @has_null, ' NULL(s) no destino.');
                    SET @need = 0;
                END
            END

            IF @need = 1
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM sys.indexes i
                    JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
                    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
                    WHERE i.object_id = OBJECT_ID(@dst_full)
                      AND c.name = @col
                      AND (i.is_primary_key=1 OR i.is_unique_constraint=1 OR i.type_desc='CLUSTERED')
                )
                BEGIN
                    PRINT CONCAT('SKIP_DEPENDENCY_PK_UQ_CL: ', @dst_full, '.', @col, ' possui PK/UNIQUE/CLUSTERED dependente.');
                    SET @need = 0;
                END
            END

            IF @need = 1
            BEGIN
                IF @execute = 1
                BEGIN
                    IF OBJECT_ID('tempdb..#IdxScripts') IS NOT NULL DROP TABLE #IdxScripts;
                    CREATE TABLE #IdxScripts
                    (
                        index_name sysname NOT NULL,
                        create_sql nvarchar(max) NOT NULL
                    );

                    ;WITH idx AS
                    (
                        SELECT i.index_id, i.name, i.is_unique, i.filter_definition
                        FROM sys.indexes i
                        WHERE i.object_id = OBJECT_ID(@dst_full)
                          AND i.type_desc = 'NONCLUSTERED'
                          AND i.is_hypothetical = 0
                          AND i.name IS NOT NULL
                          AND i.is_primary_key = 0
                          AND i.is_unique_constraint = 0
                          AND EXISTS (
                              SELECT 1
                              FROM sys.index_columns ic
                              JOIN sys.columns c
                                ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                              WHERE ic.object_id = i.object_id
                                AND ic.index_id  = i.index_id
                                AND c.name = @col
                          )
                    )
                    INSERT INTO #IdxScripts(index_name, create_sql)
                    SELECT
                        idx.name,
                        N'CREATE ' + CASE WHEN idx.is_unique = 1 THEN N'UNIQUE ' ELSE N'' END +
                        N'NONCLUSTERED INDEX ' + QUOTENAME(idx.name) + N' ON ' + @dst_full +
                        N' (' +
                            STUFF((
                                SELECT N', ' + QUOTENAME(c2.name) +
                                       CASE WHEN ic2.is_descending_key = 1 THEN N' DESC' ELSE N' ASC' END
                                FROM sys.index_columns ic2
                                JOIN sys.columns c2
                                  ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                                WHERE ic2.object_id = OBJECT_ID(@dst_full)
                                  AND ic2.index_id  = idx.index_id
                                  AND ic2.is_included_column = 0
                                ORDER BY ic2.key_ordinal
                                FOR XML PATH(''), TYPE
                            ).value('.','nvarchar(max)'), 1, 2, N'')
                        + N')' +
                        CASE
                            WHEN EXISTS (
                                SELECT 1 FROM sys.index_columns ic3
                                WHERE ic3.object_id = OBJECT_ID(@dst_full)
                                  AND ic3.index_id  = idx.index_id
                                  AND ic3.is_included_column = 1
                            )
                            THEN N' INCLUDE (' +
                                 STUFF((
                                    SELECT N', ' + QUOTENAME(c4.name)
                                    FROM sys.index_columns ic4
                                    JOIN sys.columns c4
                                      ON c4.object_id = ic4.object_id AND c4.column_id = ic4.column_id
                                    WHERE ic4.object_id = OBJECT_ID(@dst_full)
                                      AND ic4.index_id  = idx.index_id
                                      AND ic4.is_included_column = 1
                                    ORDER BY ic4.index_column_id
                                    FOR XML PATH(''), TYPE
                                 ).value('.','nvarchar(max)'), 1, 2, N'')
                                 + N')'
                            ELSE N''
                        END
                        + CASE WHEN idx.filter_definition IS NOT NULL THEN N' WHERE ' + idx.filter_definition ELSE N'' END
                        + N';'
                    FROM idx;

                    BEGIN TRY
                        DECLARE @ix sysname;
                        DECLARE cur_dropix CURSOR LOCAL FAST_FORWARD FOR
                            SELECT index_name FROM #IdxScripts;

                        OPEN cur_dropix;
                        FETCH NEXT FROM cur_dropix INTO @ix;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            SET @sql = N'DROP INDEX ' + QUOTENAME(@ix) + N' ON ' + @dst_full + N';';
                            EXEC sys.sp_executesql @sql;

                            FETCH NEXT FROM cur_dropix INTO @ix;
                        END

                        CLOSE cur_dropix;
                        DEALLOCATE cur_dropix;

                        SET @sql = N'ALTER TABLE ' + @dst_full + N' ALTER COLUMN ' + QUOTENAME(@col) + N' ' + @type_def + @coll_def + N' ' + @null_def + N';';
                        EXEC sys.sp_executesql @sql;

                        DECLARE @csql nvarchar(max);
                        DECLARE cur_crix CURSOR LOCAL FAST_FORWARD FOR
                            SELECT create_sql FROM #IdxScripts;

                        OPEN cur_crix;
                        FETCH NEXT FROM cur_crix INTO @csql;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            EXEC sys.sp_executesql @csql;
                            FETCH NEXT FROM cur_crix INTO @csql;
                        END

                        CLOSE cur_crix;
                        DEALLOCATE cur_crix;

                    END TRY
                    BEGIN CATCH
                        DECLARE @csql2 nvarchar(max);
                        DECLARE cur_crix2 CURSOR LOCAL FAST_FORWARD FOR
                            SELECT create_sql FROM #IdxScripts;

                        OPEN cur_crix2;
                        FETCH NEXT FROM cur_crix2 INTO @csql2;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            BEGIN TRY EXEC sys.sp_executesql @csql2; END TRY
                            BEGIN CATCH END CATCH;

                            FETCH NEXT FROM cur_crix2 INTO @csql2;
                        END

                        CLOSE cur_crix2;
                        DEALLOCATE cur_crix2;

                        DECLARE @errmsg nvarchar(2048) = ERROR_MESSAGE();
                        PRINT CONCAT('ALTER FAIL: ', @dst_full, '.', @col, ' -> ', @errmsg);
                        THROW;
                    END CATCH

                    DROP TABLE #IdxScripts;
                END
                ELSE
                BEGIN
                    PRINT CONCAT('-- would drop/recreate dependent nonclustered indexes on ', @dst_full, '.', @col);
                    SET @sql = N'ALTER TABLE ' + @dst_full + N' ALTER COLUMN ' + QUOTENAME(@col) + N' ' + @type_def + @coll_def + N' ' + @null_def + N';';
                    PRINT @sql;
                END
            END
        END

        FETCH NEXT FROM cur_src INTO @col, @src_type, @src_len, @src_prec, @src_scale, @src_null, @src_coll;
    END

    CLOSE cur_src;
    DEALLOCATE cur_src;

    /* DROP colunas extras (opcional) */
    IF @allow_drop = 1
    BEGIN
        IF OBJECT_ID('tempdb..#DropCols') IS NOT NULL DROP TABLE #DropCols;

        ;WITH src_cols AS (
            SELECT name FROM sys.columns WHERE object_id = OBJECT_ID(@src_full)
        ),
        dst_cols AS (
            SELECT name FROM sys.columns WHERE object_id = OBJECT_ID(@dst_full)
        )
        SELECT d.name AS col_name
        INTO #DropCols
        FROM dst_cols d
        LEFT JOIN src_cols s ON s.name = d.name
        WHERE s.name IS NULL;

        DECLARE cur_drop CURSOR FAST_FORWARD FOR
            SELECT col_name FROM #DropCols;

        OPEN cur_drop;
        FETCH NEXT FROM cur_drop INTO @col;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @skip_drop bit = 0;

            /* não mexer se houver PK / UQ / CLUSTERED */
            IF EXISTS
            (
                SELECT 1
                FROM sys.indexes i
                JOIN sys.index_columns ic
                  ON ic.object_id = i.object_id
                 AND ic.index_id  = i.index_id
                JOIN sys.columns c
                  ON c.object_id = ic.object_id
                 AND c.column_id = ic.column_id
                WHERE i.object_id = OBJECT_ID(@dst_full)
                  AND c.name = @col
                  AND (i.is_primary_key = 1 OR i.is_unique_constraint = 1 OR i.type_desc = 'CLUSTERED')
            )
            BEGIN
                PRINT CONCAT('SKIP_DROP_DEPENDENCY_PK_UQ_CL: ', @dst_full, '.', @col, ' possui PK/UNIQUE/CLUSTERED dependente.');
                SET @skip_drop = 1;
            END

            /* default */
            IF @skip_drop = 0 AND EXISTS
            (
                SELECT 1
                FROM sys.default_constraints dc
                JOIN sys.columns c
                  ON c.object_id = dc.parent_object_id
                 AND c.column_id = dc.parent_column_id
                WHERE dc.parent_object_id = OBJECT_ID(@dst_full)
                  AND c.name = @col
            )
            BEGIN
                PRINT CONCAT('SKIP_DROP_DEFAULT: ', @dst_full, '.', @col, ' possui DEFAULT constraint.');
                SET @skip_drop = 1;
            END

            /* check */
            IF @skip_drop = 0 AND EXISTS
            (
                SELECT 1
                FROM sys.check_constraints cc
                WHERE cc.parent_object_id = OBJECT_ID(@dst_full)
                  AND cc.definition LIKE '%' + @col + '%'
            )
            BEGIN
                PRINT CONCAT('SKIP_DROP_CHECK: ', @dst_full, '.', @col, ' possui CHECK constraint dependente.');
                SET @skip_drop = 1;
            END

            /* FK parent/referenced */
            IF @skip_drop = 0 AND EXISTS
            (
                SELECT 1
                FROM sys.foreign_key_columns fkc
                JOIN sys.columns c1
                  ON c1.object_id = fkc.parent_object_id
                 AND c1.column_id = fkc.parent_column_id
                WHERE fkc.parent_object_id = OBJECT_ID(@dst_full)
                  AND c1.name = @col

                UNION ALL

                SELECT 1
                FROM sys.foreign_key_columns fkc
                JOIN sys.columns c2
                  ON c2.object_id = fkc.referenced_object_id
                 AND c2.column_id = fkc.referenced_column_id
                WHERE fkc.referenced_object_id = OBJECT_ID(@dst_full)
                  AND c2.name = @col
            )
            BEGIN
                PRINT CONCAT('SKIP_DROP_FK: ', @dst_full, '.', @col, ' possui FOREIGN KEY dependente.');
                SET @skip_drop = 1;
            END

            IF @skip_drop = 0
            BEGIN
                IF @execute = 1
                BEGIN
                    BEGIN TRY
                        IF OBJECT_ID('tempdb..#DropIdxScripts') IS NOT NULL DROP TABLE #DropIdxScripts;
                        CREATE TABLE #DropIdxScripts
                        (
                            index_name sysname NOT NULL,
                            create_sql nvarchar(max) NOT NULL
                        );

                        ;WITH idx AS
                        (
                            SELECT i.index_id, i.name, i.is_unique, i.filter_definition
                            FROM sys.indexes i
                            WHERE i.object_id = OBJECT_ID(@dst_full)
                              AND i.type_desc = 'NONCLUSTERED'
                              AND i.is_hypothetical = 0
                              AND i.name IS NOT NULL
                              AND i.is_primary_key = 0
                              AND i.is_unique_constraint = 0
                              AND EXISTS
                              (
                                  SELECT 1
                                  FROM sys.index_columns ic
                                  JOIN sys.columns c
                                    ON c.object_id = ic.object_id
                                   AND c.column_id = ic.column_id
                                  WHERE ic.object_id = i.object_id
                                    AND ic.index_id  = i.index_id
                                    AND c.name = @col
                              )
                        )
                        INSERT INTO #DropIdxScripts(index_name, create_sql)
                        SELECT
                            idx.name,
                            N'CREATE ' + CASE WHEN idx.is_unique = 1 THEN N'UNIQUE ' ELSE N'' END +
                            N'NONCLUSTERED INDEX ' + QUOTENAME(idx.name) + N' ON ' + @dst_full +
                            N' (' +
                            STUFF((
                                SELECT N', ' + QUOTENAME(c2.name) +
                                       CASE WHEN ic2.is_descending_key = 1 THEN N' DESC' ELSE N' ASC' END
                                FROM sys.index_columns ic2
                                JOIN sys.columns c2
                                  ON c2.object_id = ic2.object_id
                                 AND c2.column_id = ic2.column_id
                                WHERE ic2.object_id = OBJECT_ID(@dst_full)
                                  AND ic2.index_id  = idx.index_id
                                  AND ic2.is_included_column = 0
                                  AND c2.name <> @col
                                ORDER BY ic2.key_ordinal
                                FOR XML PATH(''), TYPE
                            ).value('.','nvarchar(max)'),1,2,N'')
                            + N')' +
                            CASE
                                WHEN EXISTS
                                (
                                    SELECT 1
                                    FROM sys.index_columns ic3
                                    JOIN sys.columns c3
                                      ON c3.object_id = ic3.object_id
                                     AND c3.column_id = ic3.column_id
                                    WHERE ic3.object_id = OBJECT_ID(@dst_full)
                                      AND ic3.index_id  = idx.index_id
                                      AND ic3.is_included_column = 1
                                      AND c3.name <> @col
                                )
                                THEN N' INCLUDE (' +
                                     STUFF((
                                        SELECT N', ' + QUOTENAME(c4.name)
                                        FROM sys.index_columns ic4
                                        JOIN sys.columns c4
                                          ON c4.object_id = ic4.object_id
                                         AND c4.column_id = ic4.column_id
                                        WHERE ic4.object_id = OBJECT_ID(@dst_full)
                                          AND ic4.index_id  = idx.index_id
                                          AND ic4.is_included_column = 1
                                          AND c4.name <> @col
                                        ORDER BY ic4.index_column_id
                                        FOR XML PATH(''), TYPE
                                     ).value('.','nvarchar(max)'),1,2,N'')
                                     + N')'
                                ELSE N''
                            END
                            + CASE WHEN idx.filter_definition IS NOT NULL THEN N' WHERE ' + idx.filter_definition ELSE N'' END
                            + N';'
                        FROM idx
                        WHERE EXISTS
                        (
                            SELECT 1
                            FROM sys.index_columns icx
                            JOIN sys.columns cx
                              ON cx.object_id = icx.object_id
                             AND cx.column_id = icx.column_id
                            WHERE icx.object_id = OBJECT_ID(@dst_full)
                              AND icx.index_id  = idx.index_id
                              AND icx.is_included_column = 0
                              AND cx.name <> @col
                        );

                        DECLARE @drop_ix sysname;
                        DECLARE cur_dropix2 CURSOR LOCAL FAST_FORWARD FOR
                            SELECT index_name FROM #DropIdxScripts;

                        OPEN cur_dropix2;
                        FETCH NEXT FROM cur_dropix2 INTO @drop_ix;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            SET @sql = N'DROP INDEX ' + QUOTENAME(@drop_ix) + N' ON ' + @dst_full + N';';
                            EXEC sys.sp_executesql @sql;

                            FETCH NEXT FROM cur_dropix2 INTO @drop_ix;
                        END

                        CLOSE cur_dropix2;
                        DEALLOCATE cur_dropix2;

                        SET @sql = N'ALTER TABLE ' + @dst_full + N' DROP COLUMN ' + QUOTENAME(@col) + N';';
                        EXEC sys.sp_executesql @sql;

                        DECLARE @recreate_sql nvarchar(max);
                        DECLARE cur_recreate_ix CURSOR LOCAL FAST_FORWARD FOR
                            SELECT create_sql FROM #DropIdxScripts
                            WHERE create_sql NOT LIKE '%ON ' + @dst_full + N' ()%';

                        OPEN cur_recreate_ix;
                        FETCH NEXT FROM cur_recreate_ix INTO @recreate_sql;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            EXEC sys.sp_executesql @recreate_sql;
                            FETCH NEXT FROM cur_recreate_ix INTO @recreate_sql;
                        END

                        CLOSE cur_recreate_ix;
                        DEALLOCATE cur_recreate_ix;

                        DROP TABLE #DropIdxScripts;

                        PRINT CONCAT('DROP OK: ', @dst_full, '.', @col);
                    END TRY
                    BEGIN CATCH
                        DECLARE @errmsg_drop nvarchar(2048) = ERROR_MESSAGE();
                        PRINT CONCAT('DROP FAIL ', @col, ': ', @errmsg_drop);

                        IF OBJECT_ID('tempdb..#DropIdxScripts') IS NOT NULL
                        BEGIN
                            DECLARE @rebuild_on_fail nvarchar(max);
                            DECLARE cur_rebuild_fail CURSOR LOCAL FAST_FORWARD FOR
                                SELECT create_sql FROM #DropIdxScripts;

                            OPEN cur_rebuild_fail;
                            FETCH NEXT FROM cur_rebuild_fail INTO @rebuild_on_fail;

                            WHILE @@FETCH_STATUS = 0
                            BEGIN
                                BEGIN TRY
                                    EXEC sys.sp_executesql @rebuild_on_fail;
                                END TRY
                                BEGIN CATCH
                                END CATCH;

                                FETCH NEXT FROM cur_rebuild_fail INTO @rebuild_on_fail;
                            END

                            CLOSE cur_rebuild_fail;
                            DEALLOCATE cur_rebuild_fail;

                            DROP TABLE #DropIdxScripts;
                        END
                    END CATCH
                END
                ELSE
                BEGIN
                    PRINT CONCAT('-- would drop dependent nonclustered indexes and then drop column ', @dst_full, '.', @col);
                    PRINT N'ALTER TABLE ' + @dst_full + N' DROP COLUMN ' + QUOTENAME(@col) + N';';
                END
            END

            FETCH NEXT FROM cur_drop INTO @col;
        END

        CLOSE cur_drop;
        DEALLOCATE cur_drop;

        DROP TABLE #DropCols;
    END
END