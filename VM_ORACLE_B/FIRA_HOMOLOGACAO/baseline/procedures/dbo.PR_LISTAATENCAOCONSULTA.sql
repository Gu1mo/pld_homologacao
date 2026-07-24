CREATE PROCEDURE [dbo].[PR_LISTAATENCAOCONSULTA]
    @CPFCNPJ      VARCHAR(50),
    @NOME         NVARCHAR(4000),
    @NOMEEXATO    BIT,
    @IDUSUARIO    INT,
    @IDREQUISICAO INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NOMESEPARADO TABLE (WORD VARCHAR(500));

    INSERT INTO @NOMESEPARADO (WORD)
    SELECT value
    FROM STRING_SPLIT(@NOME, ' ');

    DECLARE @QUANTIDADENOMES INT =
    (
        SELECT COUNT(*)
        FROM @NOMESEPARADO
    );

    DECLARE @CONTAINSITEMS VARCHAR(1000);

    IF @QUANTIDADENOMES = 1
    BEGIN
        SET @CONTAINSITEMS = @NOME;
    END;

    IF @QUANTIDADENOMES > 1
    BEGIN
       SET @CONTAINSITEMS =
    'NEAR((' +
    (
        SELECT
            STUFF((
                SELECT
                    ', ' + ISNULL(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(x.WORD, ',', ''), '(', ''
                                ), ')', ''
                            ),
                            '''', ''
                        ),
                        ' '
                    )
                FROM @NOMESEPARADO x
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, '')
    ) +
    '), 100, TRUE)';
    END;

    DECLARE @TOT INT = 0;

    DECLARE @TABELAKYCTEMP TABLE
    (
        CPFCNPJ         VARCHAR(20),
        NOME            NVARCHAR(500),
        LISTA           VARCHAR(200),
        FONTE           VARCHAR(100),
        CARGOEXERCIDO   NVARCHAR(500),
        DETALHES        VARCHAR(MAX),
        TERRITORIO      NVARCHAR(300),
        DATAATUALIZACAO DATE
    );

    DECLARE @TABELAKYCPRETEMP TABLE
    (
        CPFCNPJ       VARCHAR(20),
        NOME          NVARCHAR(500),
        IDSUBLISTA    INT,
        CARGOEXERCIDO NVARCHAR(500),
        DETALHES      VARCHAR(MAX),
        TERRITORIO    NVARCHAR(300)
    );

    DECLARE @TABELAKYCPGFNTEMP TABLE
    (
        CPFCNPJ       VARCHAR(20),
        NOME          NVARCHAR(500),
        IDSUBLISTA    INT,
        CARGOEXERCIDO NVARCHAR(500),
        DETALHES      VARCHAR(MAX),
        TERRITORIO    NVARCHAR(300)
    );

    /* =========================
       NOMEEXATO = 0
       ========================= */
    IF (@NOMEEXATO = 0)
    BEGIN
        IF (ISNULL(@CPFCNPJ, '') = '') AND (ISNULL(@NOME, '') = '')
        BEGIN
            RETURN;
        END;

        IF (ISNULL(@CPFCNPJ, '') <> '') AND (ISNULL(@NOME, '') <> '')
        BEGIN
            INSERT INTO @TABELAKYCTEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE
            (
                CPFCNPJ = @CPFCNPJ
                OR
                (
                    (CHARINDEX('*', CPFCNPJ) > 0 OR CHARINDEX('X', CPFCNPJ) > 0)
                    AND SUBSTRING(CPFCNPJ, 4, 6) = SUBSTRING(@CPFCNPJ, 4, 6)
                )
            )
            AND
            (
                NOME = @NOME
                OR CONTAINS(NOME, @CONTAINSITEMS)
                OR NOME LIKE '%' + @NOME + '%'
            );

            SET @TOT = @@ROWCOUNT;
        END;

        IF (ISNULL(@CPFCNPJ, '') = '') AND (ISNULL(@NOME, '') <> '')
        BEGIN
            INSERT INTO @TABELAKYCPRETEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE
            (
                NOME = @NOME
                OR CONTAINS(NOME, @CONTAINSITEMS)
                OR NOME LIKE '%' + @NOME + '%'
            );

            INSERT INTO @TABELAKYCPGFNTEMP
            SELECT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                NULL,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                'BRASIL'
            FROM @TABELAKYCPRETEMP
            WHERE IdSublista = 44;

            INSERT INTO @TABELAKYCPRETEMP
            SELECT
    g.CPFCNPJ,
    g.NOME,
    g.IDSUBLISTA,
    '-',
    'VALOR TOTAL DA DÍVIDA: R$ ' +
    CAST(
        FORMAT(
            CAST(
                dbo.SUMPGFNDEBTS(
                    -- STRING_AGG( SUBSTRING(...), '|' )  ==>  STUFF/FOR XML
                    (
                        SELECT STUFF((
                            SELECT
                                '|' + SUBSTRING(
                                    t.Detalhes,
                                    CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19,
                                    CHARINDEX('; TIPO CREDITO', t.Detalhes) - (CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19)
                                )
                            FROM @TABELAKYCPGFNTEMP t
                            WHERE t.CPFCNPJ   = g.CPFCNPJ
                              AND t.NOME     = g.NOME
                              AND t.IDSUBLISTA = g.IDSUBLISTA
                            FOR XML PATH(''), TYPE
                        ).value('.', 'nvarchar(max)'), 1, 1, '')
                    )
                ) AS DECIMAL(30, 2)
            ),
            '#,0.00',
            'PT-BR'
        ) AS VARCHAR
    ) +
    '; DÍVIDA INTEGRANTE: ' +
    (
        -- STRING_AGG(DETALHES, ' DÍVIDA INTEGRANTE: ')  ==>  STUFF/FOR XML
        SELECT STUFF((
            SELECT
                ' DÍVIDA INTEGRANTE: ' + t2.DETALHES
            FROM @TABELAKYCPGFNTEMP t2
            WHERE t2.CPFCNPJ   = g.CPFCNPJ
              AND t2.NOME     = g.NOME
              AND t2.IDSUBLISTA = g.IDSUBLISTA
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, LEN(' DÍVIDA INTEGRANTE: '), '')
    ),
    'BRASIL'
FROM (
    SELECT DISTINCT CPFCNPJ, NOME, IDSUBLISTA
    FROM @TABELAKYCPGFNTEMP
) g;

            INSERT INTO @TABELAKYCTEMP
            SELECT
                CPFCNPJ,
                NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CARGOEXERCIDO,
                DETALHES,
                TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM @TABELAKYCPRETEMP;

            SET @TOT = @@ROWCOUNT;
        END;

        IF (ISNULL(@CPFCNPJ, '') <> '') AND (ISNULL(@NOME, '') = '')
        BEGIN
            INSERT INTO @TABELAKYCPRETEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE
                CPFCNPJ = @CPFCNPJ
                OR
                (
                    (CHARINDEX('*', CPFCNPJ) > 0 OR CHARINDEX('X', CPFCNPJ) > 0)
                    AND SUBSTRING(CPFCNPJ, 4, 6) = SUBSTRING(@CPFCNPJ, 4, 6)
                );

            INSERT INTO @TABELAKYCPGFNTEMP
            SELECT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                NULL,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                'BRASIL'
            FROM @TABELAKYCPRETEMP
            WHERE IdSublista = 44;

            INSERT INTO @TABELAKYCPRETEMP
            SELECT
    g.CPFCNPJ,
    g.NOME,
    g.IDSUBLISTA,
    '-',
    'VALOR TOTAL DA DÍVIDA: R$ ' +
    CAST(
        FORMAT(
            CAST(
                dbo.SUMPGFNDEBTS(
                    -- STRING_AGG(SUBSTRING(...), '|')
                    (
                        SELECT STUFF((
                            SELECT
                                '|' + SUBSTRING(
                                    t.Detalhes,
                                    CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19,
                                    CHARINDEX('; TIPO CREDITO', t.Detalhes)
                                      - (CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19)
                                )
                            FROM @TABELAKYCPGFNTEMP t
                            WHERE t.CPFCNPJ    = g.CPFCNPJ
                              AND t.NOME      = g.NOME
                              AND t.IDSUBLISTA = g.IDSUBLISTA
                            FOR XML PATH(''), TYPE
                        ).value('.', 'nvarchar(max)'), 1, 1, '')
                    )
                ) AS DECIMAL(30, 2)
            ),
            '#,0.00',
            'PT-BR'
        ) AS VARCHAR
    ) +
    '; DÍVIDA INTEGRANTE: ' +
    -- STRING_AGG(DETALHES, ' DÍVIDA INTEGRANTE: ')
    (
        SELECT STUFF((
            SELECT
                ' DÍVIDA INTEGRANTE: ' + t2.DETALHES
            FROM @TABELAKYCPGFNTEMP t2
            WHERE t2.CPFCNPJ    = g.CPFCNPJ
              AND t2.NOME      = g.NOME
              AND t2.IDSUBLISTA = g.IDSUBLISTA
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, LEN(' DÍVIDA INTEGRANTE: '), '')
    ),
    'BRASIL'
FROM (
    SELECT DISTINCT CPFCNPJ, NOME, IDSUBLISTA
    FROM @TABELAKYCPGFNTEMP
) g

            INSERT INTO @TABELAKYCTEMP
            SELECT
                CPFCNPJ,
                NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CARGOEXERCIDO,
                DETALHES,
                TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM @TABELAKYCPRETEMP;

            SET @TOT = @@ROWCOUNT;
        END;
    END;

    /* =========================
       NOMEEXATO = 1
       ========================= */
    IF (@NOMEEXATO = 1)
    BEGIN
        IF (ISNULL(@CPFCNPJ, '') = '') AND (ISNULL(@NOME, '') = '')
        BEGIN
            RETURN;
        END;

        IF (ISNULL(@CPFCNPJ, '') <> '') AND (ISNULL(@NOME, '') <> '')
        BEGIN
            INSERT INTO @TABELAKYCTEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE
            (
                CPFCNPJ = @CPFCNPJ
                OR SUBSTRING(CPFCNPJ, 4, 6) = SUBSTRING(@CPFCNPJ, 4, 6)
            )
            AND NOME = @NOME;

            SET @TOT = @@ROWCOUNT;
        END;

        IF (ISNULL(@CPFCNPJ, '') = '') AND (ISNULL(@NOME, '') <> '')
        BEGIN
            INSERT INTO @TABELAKYCPRETEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE NOME = @NOME;

            INSERT INTO @TABELAKYCPGFNTEMP
            SELECT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                NULL,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                'BRASIL'
            FROM @TABELAKYCPRETEMP
            WHERE IdSublista = 44;

            INSERT INTO @TABELAKYCPRETEMP
            SELECT
    g.CPFCNPJ,
    g.NOME,
    g.IDSUBLISTA,
    '-',
    'VALOR TOTAL DA DÍVIDA: R$ ' +
    CAST(
        FORMAT(
            CAST(
                dbo.SUMPGFNDEBTS(
                    (
                        -- STRING_AGG(SUBSTRING(...), '|')
                        SELECT STUFF((
                            SELECT
                                '|' + SUBSTRING(
                                    t.Detalhes,
                                    CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19,
                                    CHARINDEX('; TIPO CREDITO', t.Detalhes)
                                      - (CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19)
                                )
                            FROM @TABELAKYCPGFNTEMP t
                            WHERE t.CPFCNPJ    = g.CPFCNPJ
                              AND t.NOME      = g.NOME
                              AND t.IDSUBLISTA = g.IDSUBLISTA
                            FOR XML PATH(''), TYPE
                        ).value('.', 'nvarchar(max)'), 1, 1, '')
                    )
                ) AS DECIMAL(30, 2)
            ),
            '#,0.00',
            'PT-BR'
        ) AS VARCHAR
    ) +
    '; DÍVIDA INTEGRANTE: ' +
    (
        -- STRING_AGG(DETALHES, ' DÍVIDA INTEGRANTE: ')
        SELECT STUFF((
            SELECT
                ' DÍVIDA INTEGRANTE: ' + t2.DETALHES
            FROM @TABELAKYCPGFNTEMP t2
            WHERE t2.CPFCNPJ    = g.CPFCNPJ
              AND t2.NOME      = g.NOME
              AND t2.IDSUBLISTA = g.IDSUBLISTA
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, LEN(' DÍVIDA INTEGRANTE: '), '')
    ),
    'BRASIL'
FROM (
    SELECT DISTINCT CPFCNPJ, NOME, IDSUBLISTA
    FROM @TABELAKYCPGFNTEMP
) g


            INSERT INTO @TABELAKYCTEMP
            SELECT
                CPFCNPJ,
                NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CARGOEXERCIDO,
                DETALHES,
                TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM @TABELAKYCPRETEMP;

            SET @TOT = @@ROWCOUNT;
        END;

        IF (ISNULL(@CPFCNPJ, '') <> '') AND (ISNULL(@NOME, '') = '')
        BEGIN
            INSERT INTO @TABELAKYCPRETEMP
            SELECT DISTINCT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                CASE WHEN ISNULL(CARGOEXERCIDO, '') = '' THEN '-' ELSE CARGOEXERCIDO END AS CARGOEXERCIDO,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                CASE WHEN ISNULL(TERRITORIO, '') = '' THEN '-' ELSE TERRITORIO END AS TERRITORIO
            FROM dbo.ListaAtencao WITH (NOLOCK)
            WHERE CPFCNPJ = @CPFCNPJ;

            INSERT INTO @TABELAKYCPGFNTEMP
            SELECT
                CASE WHEN ISNULL(CPFCNPJ, '') = '' THEN '-' ELSE CPFCNPJ END AS CPFCNPJ,
                CASE WHEN ISNULL(NOME, '') = '' THEN '-' ELSE NOME END AS NOME,
                IDSUBLISTA,
                NULL,
                CASE WHEN ISNULL(DETALHES, '') = '' THEN '-' ELSE DETALHES END AS DETALHES,
                'BRASIL'
            FROM @TABELAKYCPRETEMP
            WHERE IdSublista = 44;

            INSERT INTO @TABELAKYCPRETEMP
            SELECT
    g.CPFCNPJ,
    g.NOME,
    g.IDSUBLISTA,
    '-',
    'VALOR TOTAL DA DÍVIDA: R$ ' +
    CAST(
        FORMAT(
            CAST(
                dbo.SUMPGFNDEBTS(
                    -- STRING_AGG(SUBSTRING(...), '|')
                    (
                        SELECT STUFF((
                            SELECT
                                '|' + SUBSTRING(
                                    t.Detalhes,
                                    CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19,
                                    CHARINDEX('; TIPO CREDITO', t.Detalhes)
                                      - (CHARINDEX('VALOR CONSOLIDADO: ', t.Detalhes) + 19)
                                )
                            FROM @TABELAKYCPGFNTEMP t
                            WHERE t.CPFCNPJ    = g.CPFCNPJ
                              AND t.NOME      = g.NOME
                              AND t.IDSUBLISTA = g.IDSUBLISTA
                            FOR XML PATH(''), TYPE
                        ).value('.', 'nvarchar(max)'), 1, 1, '')
                    )
                ) AS DECIMAL(30, 2)
            ),
            '#,0.00',
            'PT-BR'
        ) AS VARCHAR
    ) +
    '; DÍVIDA INTEGRANTE: ' +
    (
        -- STRING_AGG(DETALHES, ' DÍVIDA INTEGRANTE: ')
        SELECT STUFF((
            SELECT
                ' DÍVIDA INTEGRANTE: ' + t2.DETALHES
            FROM @TABELAKYCPGFNTEMP t2
            WHERE t2.CPFCNPJ    = g.CPFCNPJ
              AND t2.NOME      = g.NOME
              AND t2.IDSUBLISTA = g.IDSUBLISTA
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, LEN(' DÍVIDA INTEGRANTE: '), '')
    ),
    'BRASIL'
FROM (
    SELECT DISTINCT CPFCNPJ, NOME, IDSUBLISTA
    FROM @TABELAKYCPGFNTEMP
) g


            INSERT INTO @TABELAKYCTEMP
            SELECT
                CPFCNPJ,
                NOME,
                (SELECT NOME FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS LISTA,
                (
                    SELECT SIGLA
                    FROM LISTAATENCAOFONTE
                    WHERE ID =
                    (
                        SELECT IDFONTE
                        FROM LISTAATENCAOSUBLISTA
                        WHERE ID = IDSUBLISTA
                    )
                ) AS FONTE,
                CARGOEXERCIDO,
                DETALHES,
                TERRITORIO,
                (SELECT DATAATUALIZACAODADOS FROM LISTAATENCAOSUBLISTA WHERE ID = IDSUBLISTA) AS DATAATUALIZACAO
            FROM @TABELAKYCPRETEMP;

            SET @TOT = @@ROWCOUNT;
        END;
    END;

    INSERT INTO LISTAATENCAOCONSULTA
	(DataHora,IdUsuario,CpfCnpj,Nome,Apontado)
    VALUES
    (
        CAST(GETDATE() AS DATETIME),
        @IDUSUARIO,
        @CPFCNPJ,
        UPPER(@NOME),
        CASE WHEN @TOT = 0 THEN 0 ELSE 1 END
    );

    IF (@IDREQUISICAO IS NOT NULL)
    BEGIN
        UPDATE RelatorioGeralKYCAgendamento
        SET Listas = 2
        WHERE id = @IDREQUISICAO;
    END;

    SELECT TOP 29
        CPFCNPJ,
        NOME,
        LISTA,
        FONTE,
        CARGOEXERCIDO,
        MAX(DETALHES) AS DETALHES,
        TERRITORIO,
        DATAATUALIZACAO,
        @TOT AS TOTALLINHAS
    FROM @TABELAKYCTEMP
    WHERE FONTE IS NOT NULL
    GROUP BY
        CPFCNPJ,
        NOME,
        LISTA,
        FONTE,
        CARGOEXERCIDO,
        TERRITORIO,
        DATAATUALIZACAO;
END