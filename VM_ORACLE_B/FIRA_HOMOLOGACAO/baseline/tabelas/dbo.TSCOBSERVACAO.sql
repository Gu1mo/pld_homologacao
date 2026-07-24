CREATE TABLE [dbo].[TSCOBSERVACAO] (
    [CD_CPFCGC] varchar(20) NULL,
    [DT_NASC_FUND] datetime2(7) NOT NULL,
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [DS_OBSERVACAO] nvarchar(1000) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);