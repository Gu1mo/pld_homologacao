CREATE TABLE [dbo].[ListaAtencaoFonte] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Nome] varchar(100) NOT NULL,
    [Sigla] varchar(20) NOT NULL,
    [IdTerritorio] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_ListaAtencaoFonte] PRIMARY KEY ([Id])
);

ALTER TABLE [dbo].[ListaAtencaoFonte] ADD CONSTRAINT [FK_ListaAtencaoFonte_ListaAtencaoTerritorioFonte] FOREIGN KEY ([IdTerritorio]) REFERENCES [dbo].[ListaAtencaoTerritorioFonte] ([Id]);