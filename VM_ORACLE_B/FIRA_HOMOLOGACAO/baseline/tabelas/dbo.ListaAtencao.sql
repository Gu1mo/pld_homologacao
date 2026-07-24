CREATE TABLE [dbo].[ListaAtencao] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [CpfCnpj] varchar(50) NULL,
    [Nome] nvarchar(4000) NULL,
    [CargoExercido] nvarchar(500) NULL,
    [Detalhes] varchar(MAX) NULL,
    [Territorio] nvarchar(300) NULL,
    [IdSublista] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_ListaAtencao] PRIMARY KEY ([Id])
);

CREATE INDEX [ID001_LISTAATENCAO] ON [dbo].[ListaAtencao] ([IdSublista]);

CREATE INDEX [ID002_ListaAtencao] ON [dbo].[ListaAtencao] ([CpfCnpj]);

CREATE INDEX [ID003_ListaAtencao] ON [dbo].[ListaAtencao] ([IdSublista]);

CREATE INDEX [ID004_ListaAtencao] ON [dbo].[ListaAtencao] ([CpfCnpj], [Nome], [IdSublista], [CargoExercido], [Territorio]);

CREATE INDEX [ID005_ListaAtencao] ON [dbo].[ListaAtencao] ([Nome]);

CREATE INDEX [IX_ListaAtencao_CpfCnpj] ON [dbo].[ListaAtencao] ([CpfCnpj]);

CREATE INDEX [IX_ListaAtencao_Nome] ON [dbo].[ListaAtencao] ([Nome]);