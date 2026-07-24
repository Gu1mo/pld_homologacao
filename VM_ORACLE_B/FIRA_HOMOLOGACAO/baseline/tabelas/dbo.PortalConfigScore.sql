CREATE TABLE [dbo].[PortalConfigScore] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Item] varchar(100) NULL,
    [Tipo] varchar(50) NULL,
    [Peso] tinyint NULL,
    [IdUsuario] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_PortalConfigScore] PRIMARY KEY ([Id])
);