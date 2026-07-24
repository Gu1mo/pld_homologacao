CREATE TABLE [dbo].[ST_ATIVO_BOVESPA] (
    [TIPREG] float NULL,
    [DATA] int NULL,
    [CODBDI] float NULL,
    [CODNEG] varchar(50) NULL,
    [TPMERC] float NULL,
    [NOMRES] varchar(50) NULL,
    [ESPECI] varchar(50) NULL,
    [PRAZOT] varchar(50) NULL,
    [MOEDA] varchar(50) NULL,
    [PREABE] float NULL,
    [PREMAX] float NULL,
    [PREMIN] float NULL,
    [PREMED] float NULL,
    [PREULT] float NULL,
    [PREOFC] float NULL,
    [PREOFV] float NULL,
    [TOTNEG] float NULL,
    [QUATOT] float NULL,
    [VOLTOT] float NULL,
    [PREEXE] float NULL,
    [INDOPC] float NULL,
    [DATVEN] varchar(50) NULL,
    [FATCOT] float NULL,
    [PTOEXE] float NULL,
    [CODISI] varchar(50) NULL,
    [DISMES] float NULL,
    [DT_PERIODO] smalldatetime NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);

CREATE INDEX [ID001_ST_ATIVO_BOVESPA] ON [dbo].[ST_ATIVO_BOVESPA] ([DT_PERIODO]);

CREATE INDEX [IDX_99] ON [dbo].[ST_ATIVO_BOVESPA] ([DT_PERIODO]);

CREATE INDEX [IDX01_ST_ATIVO_BOVESPA] ON [dbo].[ST_ATIVO_BOVESPA] ([DT_PERIODO]);