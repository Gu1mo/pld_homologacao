CREATE TABLE [dbo].[ST_BMF_NEGOCIOS_NC] (
    [DT_NEGOCIO] smalldatetime NULL,
    [DT_DATMOV] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_COMMOD] varchar(30) NULL,
    [CD_SERIE] char(4) NULL,
    [CD_NATOPE] varchar(1) NULL,
    [QT_QTDDET] float NULL,
    [PR_NEGOCIO] float NULL,
    [TP_NEGOCIO] varchar(21) NULL,
    [VL_VALOPE] float NULL,
    [VL_CORNEG] float NULL,
    [NR_NEGOCIO] numeric(12,0) NULL,
    [NR_NEGOCIO_CAS] numeric(12,0) NULL,
    [NM_CONTRAPAR] varchar(60) NULL,
    [IN_GARANT] char(1) NULL,
    [VL_VLRNEG] numeric(16,2) NULL,
    [CD_MERCAD] char(3) NULL,
    [CD_CONTRAPARTE] numeric(6,0) NULL,
    [NUM_TRDE_GTS] varchar(2) NULL,
    [HR_NEGOCIO] varchar(8) NULL,
    [CD_CORRET] numeric(6,0) NULL,
    [CD_CANAL] varchar(4) NULL,
    [CD_OPERADOR] varchar(8) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE INDEX [ID001_ST_BMF_NEGOCIOS_NC] ON [dbo].[ST_BMF_NEGOCIOS_NC] ([CD_NATOPE], [CD_CONTRAPARTE], [DT_NEGOCIO], [TP_NEGOCIO]);