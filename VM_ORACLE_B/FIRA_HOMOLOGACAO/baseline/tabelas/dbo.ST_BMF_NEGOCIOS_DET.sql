CREATE TABLE [dbo].[ST_BMF_NEGOCIOS_DET] (
    [DT_DATORD] datetime NULL,
    [NR_SEQORD] numeric(7,0) NULL,
    [IN_SITUAC] nchar(1) NULL,
    [DT_HORORD] datetime NULL,
    [DT_DATMOV] datetime NULL,
    [TP_ORDEM] numeric(2,0) NULL,
    [QT_ORDEM] float NULL,
    [CD_CONTRAPARTE] numeric(6,0) NULL,
    [NR_NEGOCIO_CAS] numeric(12,0) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);