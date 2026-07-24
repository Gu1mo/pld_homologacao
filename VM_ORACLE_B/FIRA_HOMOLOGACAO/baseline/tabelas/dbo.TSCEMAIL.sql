CREATE TABLE [dbo].[TSCEMAIL] (
    [CD_CPFCGC] varchar(20) NULL,
    [DT_NASC_FUND] datetime2(7) NOT NULL,
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [NR_SEQ_E_MAIL] numeric(2,0) NOT NULL,
    [NM_E_MAIL] nvarchar(100) NOT NULL,
    [IN_PRINCIPAL] nchar(1) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);