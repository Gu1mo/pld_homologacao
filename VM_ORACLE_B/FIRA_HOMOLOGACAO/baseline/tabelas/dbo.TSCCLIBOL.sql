CREATE TABLE [dbo].[TSCCLIBOL] (
    [DT_NASC_FUND] datetime2(7) NULL,
    [CD_CON_DEP] numeric(5,0) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [CD_CLIENTE] int NULL,
    [CD_ASSESSOR] numeric(20,0) NULL,
    [IN_CONTA_INV] nchar(5) NULL,
    [IN_SITUAC] nchar(5) NULL,
    [IND_CAD_SIMP] nchar(5) NULL,
    [DT_ULT_OPER] datetime2(7) NULL,
    [DT_CRIACAO] datetime2(7) NULL,
    [TP_CLIENTE] numeric(20,0) NULL,
    [TP_INVESTIDOR] numeric(20,0) NULL,
    [DT_ATUALIZ] datetime2(7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [NM_COMPL_NOME] nvarchar(600) NULL,
    [CD_OPERAC_CVM] varchar(130) NULL,
    [IN_QUALIFICADO] char(1) NULL
);

CREATE INDEX [ID001_TSCCLIBOL] ON [dbo].[TSCCLIBOL] ([DT_NASC_FUND], [CD_CON_DEP], [CD_CPFCGC]);