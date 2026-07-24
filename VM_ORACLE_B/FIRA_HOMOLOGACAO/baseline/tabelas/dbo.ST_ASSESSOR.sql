CREATE TABLE [dbo].[ST_ASSESSOR] (
    [CD_ASSESSOR] numeric(5,0) NOT NULL,
    [DS_ASSESSOR] varchar(60) NOT NULL,
    [CD_SITUACAO] char(1) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);