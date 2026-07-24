CREATE TABLE [dbo].[RelatorioGeralKYCListasTerritorio] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Territorio] nvarchar(200) NULL,
    [IdSublista] int NULL,
    [IdRequisicao] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_RelatorioGeralKYCListasTerritorio] PRIMARY KEY ([Id])
);