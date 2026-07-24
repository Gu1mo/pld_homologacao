CREATE TABLE [dbo].[ST_EXTRATO_CC] (
    [CD_CLIENTE] int NOT NULL,
    [DT_REFERENCIA] datetime NULL,
    [DT_LIQUIDACAO] datetime NULL,
    [DT_VALOR] datetime2(7) NULL,
    [DS_LANCAMENTO] varchar(180) NULL,
    [NM_CLIENTE] varchar(400) NULL,
    [ENDERECO] varchar(137) NULL,
    [BAIRRO] varchar(118) NULL,
    [CIDADE] varchar(128) NULL,
    [ESTADO] varchar(14) NULL,
    [VL_LANCAMENTO] decimal(38,20) NULL,
    [CD_HISTORICO] int NULL,
    [NR_LANCAMENTO] varchar(150) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE INDEX [idx2_rel_patr_movcc] ON [dbo].[ST_EXTRATO_CC] ([DT_REFERENCIA]);

CREATE INDEX [IX_Rel_pat_movcc] ON [dbo].[ST_EXTRATO_CC] ([CD_CLIENTE], [DT_REFERENCIA]);