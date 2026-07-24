CREATE TABLE [dbo].[TSCENDE] (
    [DT_NASC_FUND] datetime2(7) NULL,
    [CD_CON_DEP] numeric(2,0) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [NM_LOGRADOURO] varchar(MAX) NULL,
    [NR_PREDIO] varchar(MAX) NULL,
    [NM_COMP_ENDE] varchar(MAX) NULL,
    [NM_BAIRRO] varchar(MAX) NULL,
    [NM_CIDADE] varchar(MAX) NULL,
    [SG_ESTADO] varchar(MAX) NULL,
    [SG_PAIS] varchar(MAX) NULL,
    [NM_E_MAIL] varchar(MAX) NULL,
    [NR_TELEFONE] numeric(10,0) NULL,
    [CD_CEP] numeric(5,0) NULL,
    [CD_CEP_EXT] numeric(4,0) NULL,
    [CD_DDD_TEL] numeric(7,0) NULL,
    [IN_ENDE_CORR] char(1) NULL,
    [NR_SEQ_ENDE] numeric(2,0) NULL,
    [DT_ATUALIZ] datetime2(7) NULL,
    [CD_DDD_CELULAR1] numeric(7,0) NULL,
    [NR_CELULAR1] numeric(15,0) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE INDEX [ID001_TSCENDE] ON [dbo].[TSCENDE] ([DT_NASC_FUND], [CD_CON_DEP], [CD_CPFCGC]);