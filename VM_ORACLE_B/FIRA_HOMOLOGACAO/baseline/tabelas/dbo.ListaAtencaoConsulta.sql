CREATE TABLE [dbo].[ListaAtencaoConsulta] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [DataHora] datetime NOT NULL,
    [IdUsuario] int NOT NULL,
    [CpfCnpj] varchar(20) NULL,
    [Nome] nvarchar(500) NULL,
    [Apontado] bit NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ListaAtencaoConsulta] PRIMARY KEY ([Id])
);