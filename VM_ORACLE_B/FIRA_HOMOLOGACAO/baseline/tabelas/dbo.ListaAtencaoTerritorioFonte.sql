CREATE TABLE [dbo].[ListaAtencaoTerritorioFonte] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Nome] nvarchar(300) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_ListaAtencaoTerritorioFonte] PRIMARY KEY ([Id])
);