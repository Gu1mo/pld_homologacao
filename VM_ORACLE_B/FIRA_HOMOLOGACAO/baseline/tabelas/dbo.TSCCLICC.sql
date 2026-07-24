CREATE TABLE [dbo].[TSCCLICC] (
    [CD_CLIENTE] int NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [DT_NASC_FUND] datetime2(7) NOT NULL,
    [CD_CON_DEP] numeric(2,0) NOT NULL,
    [DT_CRIACAO] datetime2(7) NOT NULL,
    [DT_ATUALIZ] datetime2(7) NOT NULL,
    [CD_BANCO] nvarchar(8) NULL,
    [NR_AGENCIA] nvarchar(5) NULL,
    [DV_AGENCIA] nchar(1) NULL,
    [IN_CONTA_INV] varchar(3) NULL,
    [IN_SITUAC] nvarchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);