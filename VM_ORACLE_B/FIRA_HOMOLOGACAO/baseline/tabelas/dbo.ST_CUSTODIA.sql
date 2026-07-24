CREATE TABLE [dbo].[ST_CUSTODIA] (
    [DT_CUSTODIA] date NULL,
    [CD_CLIENTE] numeric(19,0) NULL,
    [COD_NEG] varchar(20) NULL,
    [DESC_CARTEIRA] varchar(60) NULL,
    [VL_POSI] float NULL,
    [PREC_MED] float NULL,
    [QTDE_DISP] float NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [FAT_COT] float NULL
);