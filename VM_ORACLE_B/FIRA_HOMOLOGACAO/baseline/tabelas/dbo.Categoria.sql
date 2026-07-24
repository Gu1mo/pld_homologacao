CREATE TABLE [dbo].[Categoria] (
    [ID] int IDENTITY(1,1) NOT NULL,
    [INDICE] int NULL,
    [NOME] nvarchar(500) NULL,
    [ICONE] varchar(100) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_Categoria] PRIMARY KEY ([ID])
);