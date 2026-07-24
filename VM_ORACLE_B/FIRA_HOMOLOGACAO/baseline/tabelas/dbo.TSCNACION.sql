CREATE TABLE [dbo].[TSCNACION] (
    [CD_NACION] numeric(1,0) NOT NULL,
    [DS_NACION] varchar(40) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);