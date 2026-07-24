CREATE TABLE [dbo].[TSCDXCLI_CLIGER] (
    [NUM_SEQ_CLIENTE] int NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [CD_CON_DEP] int NULL,
    [DT_NASC_FUND] datetime2(7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);