CREATE TABLE [dbo].[HISTORICOCONSULTAKYC] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [DataHora] datetime NOT NULL,
    [IdUsuario] int NOT NULL,
    [CpfCnpj] varchar(20) NULL,
    [Nome] nvarchar(500) NULL,
    [Apontado] bit NOT NULL,
    [TipoConsulta] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);