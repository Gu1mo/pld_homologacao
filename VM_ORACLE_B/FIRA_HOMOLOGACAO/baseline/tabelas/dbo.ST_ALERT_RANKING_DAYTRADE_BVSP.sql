CREATE TABLE [dbo].[ST_ALERT_RANKING_DAYTRADE_BVSP] (
    [DATA] date NULL,
    [CD_CLIENTE] int NOT NULL,
    [ATV_NEG_DT] varchar(MAX) NULL,
    [ATV_TOT] varchar(MAX) NULL,
    [RSLT_FIN] numeric(17,2) NULL,
    [MED_RSLT_FIN] numeric(17,2) NULL,
    [DES_RSLT_FIN] numeric(17,2) NULL,
    [IND_ACERTO] numeric(17,2) NULL,
    [MED_IND_ACERTO] numeric(17,2) NULL,
    [DES_IND_ACERTO] numeric(17,2) NULL,
    [IND_ERRO] numeric(17,2) NULL,
    [MED_IND_ERRO] numeric(17,2) NULL,
    [DES_IND_ERRO] numeric(17,2) NULL,
    [QTD_DT] int NULL,
    [QTD_DIAS_DT] int NULL,
    [QTD_DIAS_OPE] int NULL,
    [DIAS_PROP] numeric(17,2) NULL,
    [VOLUME_DT] numeric(17,2) NULL,
    [RENT_PROP] numeric(17,5) NULL,
    [VOLUME_TOT] numeric(17,2) NULL,
    [DT_PROP] numeric(17,2) NULL,
    [CONTRA_IN] numeric(8,0) NULL,
    [CONTRA_OUT] numeric(8,0) NULL,
    [DAYTRADISTA] varchar(1) NOT NULL,
    [ALT_FQ] varchar(1) NOT NULL,
    [RSLT_FIN_ABS] numeric(17,2) NULL,
    [CD_PAPEL] nvarchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE INDEX [ID001_ST_ALERT_RANKING_DAYTRADE_BVSP] ON [dbo].[ST_ALERT_RANKING_DAYTRADE_BVSP] ([CD_CLIENTE], [DATA]);

CREATE INDEX [ID002_ST_ALERT_RANKING_DAYTRADE_BVSP] ON [dbo].[ST_ALERT_RANKING_DAYTRADE_BVSP] ([DATA]);