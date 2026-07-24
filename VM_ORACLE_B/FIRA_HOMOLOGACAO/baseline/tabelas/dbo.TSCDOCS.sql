CREATE TABLE [dbo].[TSCDOCS] (
    [DT_NASC_FUND] datetime2(7) NOT NULL,
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [IN_PROCUR] nchar(1) NOT NULL,
    [DT_VALIDADE] datetime2(7) NOT NULL,
    [DT_FICH_CAD] datetime2(7) NULL,
    [IN_CONTR_BOLSA] nchar(1) NOT NULL,
    [IN_CONTR_BMF] nchar(1) NOT NULL,
    [IN_CONTR_SOCIAL] nchar(1) NOT NULL,
    [IN_CONTR_OPC] nchar(1) NOT NULL,
    [IN_CONTR_TER] nchar(1) NOT NULL,
    [IN_CONTR_TST] nchar(1) NOT NULL,
    [IN_CONTR_BTC] nchar(1) NOT NULL,
    [IN_CONTA_MARGEM] nchar(1) NOT NULL,
    [TM_STAMP] datetime2(7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);