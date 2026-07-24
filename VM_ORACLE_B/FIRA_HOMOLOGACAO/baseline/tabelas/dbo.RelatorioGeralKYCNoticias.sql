CREATE TABLE [dbo].[RelatorioGeralKYCNoticias] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [titulo] varchar(MAX) NULL,
    [url] nvarchar(1000) NULL,
    [descricao] varchar(MAX) NULL,
    [dataPublicacao] datetime NULL,
    [fonte] nvarchar(100) NULL,
    [sentimento] varchar(50) NULL,
    [IdRequisicao] int NULL,
    [keywords] varchar(MAX) NULL,
    [match] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_RelatorioGeralKYCNoticias] PRIMARY KEY ([Id])
);