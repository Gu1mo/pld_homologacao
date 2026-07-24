CREATE TABLE [dbo].[Permissao] (
    [Usuario_Id] int NOT NULL,
    [Menu_Id] int NOT NULL,
    [CODINTERNO] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);