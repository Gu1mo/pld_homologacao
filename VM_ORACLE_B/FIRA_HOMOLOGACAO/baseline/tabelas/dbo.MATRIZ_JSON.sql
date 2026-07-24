CREATE TABLE [dbo].[MATRIZ_JSON] (
    [DT_LOG] date NOT NULL,
    [DT_MATRIZ] date NOT NULL,
    [ID_CORRETORA] int NOT NULL,
    [NM_CORRETORA] varchar(400) NOT NULL,
    [MATRIZ] varchar(MAX) NULL,
    [MATRIZ_2] varchar(MAX) NULL,
    [MATRIZ_3] varchar(MAX) NULL,
    [MATRIZ_4] varchar(MAX) NULL,
    [MATRIZ_5] varchar(MAX) NULL,
    [MATRIZ_6] varchar(MAX) NULL,
    [MATRIZ_7] varchar(MAX) NULL,
    [MATRIZ_8] varchar(MAX) NULL,
    [MATRIZ_9] varchar(MAX) NULL,
    [MATRIZ_10] varchar(MAX) NULL,
    [Id] int IDENTITY(1,1) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_MATRIZ_JSON] PRIMARY KEY ([Id])
);