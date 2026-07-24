CREATE TABLE [dbo].[TSCCLICOMP] (
    [DT_NASC_FUND] datetime2(7) NULL,
    [CD_CON_DEP] numeric(2,0) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [NM_PAI] nvarchar(160) NULL,
    [NM_MAE] nvarchar(160) NULL,
    [NM_CONJUGE] nvarchar(160) NULL,
    [DS_CARGO] nvarchar(140) NULL,
    [CD_NACION] numeric(4,0) NULL,
    [CD_ATIV] numeric(13,0) NULL,
    [NM_EMPRESA] nvarchar(160) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [CD_CNPJ_EMPRESA] varchar(20) NULL
);