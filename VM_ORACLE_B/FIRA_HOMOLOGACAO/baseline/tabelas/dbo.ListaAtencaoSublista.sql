CREATE TABLE [dbo].[ListaAtencaoSublista] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Nome] varchar(200) NOT NULL,
    [DataAtualizacaoDados] date NOT NULL,
    [DataColetaDados] date NOT NULL,
    [IdFonte] int NOT NULL,
    [IdPeriodicidade] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_ListaAtencaoSublista] PRIMARY KEY ([Id])
);

ALTER TABLE [dbo].[ListaAtencaoSublista] ADD CONSTRAINT [FK_ListaAtencaoSublista_ListaAtencaoPeriodicidade] FOREIGN KEY ([IdPeriodicidade]) REFERENCES [dbo].[ListaAtencaoPeriodicidade] ([Id]);

ALTER TABLE [dbo].[ListaAtencaoSublista] ADD CONSTRAINT [FK_ListaAtencaoSublista_ListaAtencaoSublista] FOREIGN KEY ([Id]) REFERENCES [dbo].[ListaAtencaoSublista] ([Id]);