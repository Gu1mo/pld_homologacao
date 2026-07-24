CREATE TABLE [dbo].[TSCCLIGRUPO] (
    [CD_GRUPO] numeric(3,0) NOT NULL,
    [NM_GRUPO] varchar(30) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);