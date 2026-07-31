DECLARE @fk_disable NVARCHAR(MAX) = '';
SELECT @fk_disable = @fk_disable + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(fk.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + ' NOCHECK CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys fk WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.TesteDatas');
EXEC sp_executesql @fk_disable;

EXEC sp_rename N'dbo.TesteDatas', N'TesteDatas_old_20260731_175727';

DECLARE @constraints_antigas NVARCHAR(MAX) = '';
SELECT @constraints_antigas = @constraints_antigas + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name) + ' DROP CONSTRAINT ' + QUOTENAME(c.name) + ';'
FROM sys.objects c
JOIN sys.tables t ON c.parent_object_id = t.object_id
WHERE t.name = N'TesteDatas_old_20260731_175727' AND t.schema_id = SCHEMA_ID(N'dbo') AND c.type IN ('PK', 'UQ', 'C', 'D', 'F');
EXEC sp_executesql @constraints_antigas;

CREATE TABLE [dbo].[TesteDatas] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [DataInicio] datetime2(0) NOT NULL,
    [DataFim] datetime2(0) NOT NULL,
    [id_teste] int NULL,
    CONSTRAINT [PK_TesteDatas] PRIMARY KEY ([Id])
);

SET IDENTITY_INSERT dbo.TesteDatas ON;

INSERT INTO dbo.TesteDatas ([DataFim], [DataInicio], [Id])
SELECT [DataFim], [DataInicio], [Id] FROM dbo.TesteDatas_old_20260731_175727;

SET IDENTITY_INSERT dbo.TesteDatas OFF;

DROP TABLE dbo.TesteDatas_old_20260731_175727;

DECLARE @fk_enable NVARCHAR(MAX) = '';
SELECT @fk_enable = @fk_enable + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(fk.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + ' CHECK CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys fk WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.TesteDatas');
EXEC sp_executesql @fk_enable;