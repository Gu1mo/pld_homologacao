CREATE TABLE [dbo].[ST_ALERT_OMG_BMF] (
    [DATA] date NULL,
    [CD_CLIENTE] int NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [CD_CONTRAPARTE] varchar(2000) NULL,
    [VINCULOS] varchar(500) NULL,
    [QTD_NEGOCIO_MES_GRUPO] int NULL,
    [CONCENTRACAO] decimal(17,2) NULL,
    [QTD_CONTRATO_MES_GRUPO] decimal(17,2) NULL,
    [DT_FIRA] datetime NULL,
    [NR_NEGOCIO] varchar(MAX) NULL,
    [QTD_CONTRATO_CLIENTE] decimal(17,2) NULL
);