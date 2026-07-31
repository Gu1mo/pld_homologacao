DECLARE @fk_disable NVARCHAR(MAX) = '';
SELECT @fk_disable = @fk_disable + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(fk.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + ' NOCHECK CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys fk WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.ST_LOG_CARGA');
EXEC sp_executesql @fk_disable;

EXEC sp_rename N'dbo.ST_LOG_CARGA', N'ST_LOG_CARGA_old_20260731_011919';

CREATE TABLE [dbo].[ST_LOG_CARGA] (
    [IDLOG] int IDENTITY(1,1) NOT NULL,
    [IDPROCESSO] int NOT NULL,
    [PROCESSO] varchar(255) NULL,
    [DTCARGA] date NULL,
    [DTINICIO] datetime NULL,
    [DTFIM] datetime NULL,
    [STATUS] varchar(20) NULL,
    [TEMPO_EXECUCAO] AS (CONVERT([time],isnull([DTFIM],getdate())-[DTINICIO])),
    [ERRO] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

SET IDENTITY_INSERT dbo.ST_LOG_CARGA ON;

INSERT INTO dbo.ST_LOG_CARGA ([DTCARGA], [DTFIM], [DTINICIO], [DT_FIRA], [ERRO], [IDLOG], [IDPROCESSO], [PROCESSO], [STATUS])
SELECT [DTCARGA], [DTFIM], [DTINICIO], [DT_FIRA], [ERRO], [IDLOG], [IDPROCESSO], [PROCESSO], [STATUS] FROM dbo.ST_LOG_CARGA_old_20260731_011919;

SET IDENTITY_INSERT dbo.ST_LOG_CARGA OFF;

DROP TABLE dbo.ST_LOG_CARGA_old_20260731_011919;

DECLARE @fk_enable NVARCHAR(MAX) = '';
SELECT @fk_enable = @fk_enable + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(fk.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + ' CHECK CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys fk WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.ST_LOG_CARGA');
EXEC sp_executesql @fk_enable;