CREATE TABLE [dbo].[TSCSFPSUBGRU] (
    [CD_GRUPO] int NULL,
    [CD_SUBGRUPO] int NULL,
    [DS_SUBGRUPO] varchar(150) NULL,
    [CD_CLASSIFICACAO] varchar(2) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);