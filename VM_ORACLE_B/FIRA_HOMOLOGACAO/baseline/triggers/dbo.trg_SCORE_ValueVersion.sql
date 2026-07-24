--------------------------------------------------------------ETAPA 3 --DROP TRIGGER dbo.trg_SCORE_ValueVersion
CREATE   TRIGGER [dbo].[trg_SCORE_ValueVersion]
ON [dbo].[score]
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT UPDATE([value]) RETURN;

  BEGIN TRY
    DECLARE @now     datetime2(0) = SYSDATETIME();                                  -- precisão em segundos
    DECLARE @now_min datetime2(0) = DATEADD(minute, DATEDIFF(minute, 0, @now), 0);  -- minuto truncado

    -- Linhas cujo valor realmente mudou
    DECLARE @U TABLE(
      id        bigint       PRIMARY KEY,
      [value]   int          NOT NULL,
      old_value int          NULL
    );

    INSERT INTO @U (id, [value], old_value)
    SELECT i.id, i.[value], d.[value]
    FROM inserted i
    JOIN deleted  d ON d.id = i.id
    WHERE ISNULL(i.[value], -2147483648) <> ISNULL(d.[value], -2147483648);

    IF NOT EXISTS (SELECT 1 FROM @U) RETURN;

    --------------------------------------------------------------
    -- Resolver usuário do portal (comparando por SEGUNDOS):
    --------------------------------------------------------------
    DECLARE @portal_user nvarchar(200);

    -- (1) mesmo segundo (truncate milissegundos de ar.[date])
    SELECT TOP (1) @portal_user = up.Usuario
    FROM dbo.audit_risk ar
    LEFT JOIN dbo.usuarioportal up ON up.id = ar.userid
    WHERE CAST(ar.[date] AS datetime2(0)) = @now
    ORDER BY ar.id DESC;

    -- (2) mesmo minuto (sem precisar truncar @now; compara por DATEDIFF)
    IF @portal_user IS NULL
    BEGIN
      SELECT TOP (1) @portal_user = up.Usuario
      FROM dbo.audit_risk ar
      LEFT JOIN dbo.usuarioportal up ON up.id = ar.userid
      WHERE DATEDIFF(minute, ar.[date], @now) = 0
      ORDER BY ar.[date] DESC, ar.id DESC;
    END

    -- (3) janela curta ±5s (comparação usando segundos; truncando ambos os lados)
    IF @portal_user IS NULL
    BEGIN
      SELECT TOP (1) @portal_user = up.Usuario
      FROM dbo.audit_risk ar
      LEFT JOIN dbo.usuarioportal up ON up.id = ar.userid
      WHERE CAST(ar.[date] AS datetime2(0))
            BETWEEN DATEADD(second, -5, @now) AND DATEADD(second, 5, @now)
      ORDER BY ABS(DATEDIFF(second, CAST(ar.[date] AS datetime2(0)), @now)) ASC,
               ar.id DESC;
    END

    --------------------------------------------------------------
    -- Fecha versão vigente
    --------------------------------------------------------------
    UPDATE v
      SET v.effective_to = @now
    FROM dbo.SCORE_VALUE_VERSION v WITH (UPDLOCK, HOLDLOCK)
    JOIN @U u ON u.id = v.score_id
    WHERE v.effective_to IS NULL;

    --------------------------------------------------------------
    -- Abre nova versão (changed_by = portal se achou; senão login SQL)
    --------------------------------------------------------------
    INSERT INTO dbo.SCORE_VALUE_VERSION
      (score_id, [value], effective_from, effective_to, changed_by)
    SELECT u.id, u.[value], @now, NULL, COALESCE(@portal_user, SUSER_SNAME())
    FROM @U u;

  END TRY
  BEGIN CATCH
    DECLARE @msg nvarchar(4000) =
      CONCAT('trg_SCORE_ValueVersion failed. Error ',
             ERROR_NUMBER(), ' at line ', ERROR_LINE(), ': ', ERROR_MESSAGE());
    THROW 50001, @msg, 1;
  END CATCH
END