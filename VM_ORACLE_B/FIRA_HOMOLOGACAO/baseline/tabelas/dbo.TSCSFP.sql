CREATE TABLE [dbo].[TSCSFP] (
    [CD_CPFCGC] varchar(20) NULL,
    [DT_NASC_FUND] datetime2(7) NOT NULL,
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [NR_SEQ_SFP] numeric(3,0) NOT NULL,
    [CD_SFPGRUPO] numeric(2,0) NOT NULL,
    [CD_SFPSUBGRUPO] numeric(2,0) NOT NULL,
    [DS_BEN] nvarchar(160) NOT NULL,
    [VL_BEN] numeric(35,2) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);