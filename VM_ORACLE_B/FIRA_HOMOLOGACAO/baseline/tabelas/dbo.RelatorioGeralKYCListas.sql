CREATE TABLE [dbo].[RelatorioGeralKYCListas] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [CpfCnpj] varchar(20) NULL,
    [Nome] nvarchar(2000) NULL,
    [Lista] nvarchar(300) NULL,
    [Fonte] nvarchar(100) NULL,
    [CargoExercido] nvarchar(200) NULL,
    [Detalhes] nvarchar(4000) NULL,
    [Territorio] nvarchar(200) NULL,
    [DataAtualizacao] date NULL,
    [IdRequisicao] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_RelatorioGeralKYCListas] PRIMARY KEY ([Id])
);