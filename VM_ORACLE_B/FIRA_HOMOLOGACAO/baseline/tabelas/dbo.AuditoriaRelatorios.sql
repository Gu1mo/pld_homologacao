CREATE TABLE [dbo].[AuditoriaRelatorios] (
    [id] int IDENTITY(1,1) NOT NULL,
    [userId] int NULL,
    [data] smalldatetime NULL,
    [idRelatorio] varchar(4000) NULL,
    [apiRoute] varchar(1000) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_AuditoriaRelatorios] PRIMARY KEY ([id])
);