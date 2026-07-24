CREATE TABLE [dbo].[TSCEMITORDEM] (
    [DT_NASC_FUND] datetime2(7) NULL,
    [CD_CON_DEP] int NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [NM_EMIT_ORDEM] nvarchar(160) NULL,
    [CD_CPFCGC_EMIT] varchar(100) NULL,
    [CD_DOC_IDENT_EMIT] varchar(100) NULL,
    [IN_PRINCIPAL] varchar(5) NULL,
    [CD_SISTEMA] varchar(10) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);