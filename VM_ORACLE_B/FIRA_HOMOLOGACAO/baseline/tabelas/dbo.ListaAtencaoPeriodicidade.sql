CREATE TABLE [dbo].[ListaAtencaoPeriodicidade] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Nome] varchar(50) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_ListaAtencaoPeriodicidade] PRIMARY KEY ([Id])
);