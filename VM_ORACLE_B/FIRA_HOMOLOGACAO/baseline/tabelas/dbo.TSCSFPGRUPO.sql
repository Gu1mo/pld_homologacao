CREATE TABLE [dbo].[TSCSFPGRUPO] (
    [CD_GRUPO] int NULL,
    [DS_GRUPO] nvarchar(150) NULL,
    [TP_CLASSIFICACAO] varchar(1) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);