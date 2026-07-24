CREATE TABLE [dbo].[ConfigRelatorio] (
    [id] int IDENTITY(1,1) NOT NULL,
    [nome] varchar(50) NULL,
    [aba] int NULL,
    [titulo] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ConfigRelatorio] PRIMARY KEY ([id])
);