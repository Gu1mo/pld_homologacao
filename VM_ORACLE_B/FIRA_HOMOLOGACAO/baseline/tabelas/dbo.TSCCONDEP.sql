CREATE TABLE [dbo].[TSCCONDEP] (
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [DS_CON_DEP] varchar(40) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);