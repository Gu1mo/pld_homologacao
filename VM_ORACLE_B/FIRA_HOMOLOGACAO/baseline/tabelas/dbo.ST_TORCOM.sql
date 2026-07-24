CREATE TABLE [dbo].[ST_TORCOM] (
    [CD_BOLSAMOV] varchar(2) NULL,
    [CD_CARLIQ] numeric(3,0) NULL,
    [CD_CLIENTE] int NULL,
    [CD_CLIENTE_BRO] int NULL,
    [CD_CLIENTE_FIN] int NULL,
    [CD_NATOPE] char(1) NULL,
    [CD_NEGOCIO] varchar(12) NULL,
    [DT_DATORD] datetime2(7) NULL,
    [DT_NEGOCIO] datetime2(7) NULL,
    [IN_LIQUIDA] varchar(1) NULL,
    [NR_NEGOCIO] numeric(9,0) NULL,
    [NR_SEQORD] numeric(9,0) NULL,
    [NR_SUBSEQ] numeric(5,0) NULL,
    [NR_SEQCOMI] numeric(10,0) NULL,
    [QT_QTDESP] numeric(15,4) NULL,
    [TP_NEGOCIO] char(3) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);