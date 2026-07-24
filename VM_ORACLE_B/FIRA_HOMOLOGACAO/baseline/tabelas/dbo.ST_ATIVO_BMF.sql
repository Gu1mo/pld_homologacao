CREATE TABLE [dbo].[ST_ATIVO_BMF] (
    [DATA] smalldatetime NULL,
    [CD_COMMOD] varchar(MAX) NULL,
    [CD_MERCAD] varchar(160) NULL,
    [CD_SERIE] varchar(MAX) NULL,
    [VOLUME] float NULL,
    [QT_CONTRATOS_ABERTOS] float NULL,
    [QT_NEGOCIOS] float NULL,
    [QT_CONTRATOS_DIA] float NULL,
    [PR_ABERTURA] float NULL,
    [PR_MINIMO] float NULL,
    [PR_MAXIMO] float NULL,
    [PR_MEDIO] float NULL,
    [PR_FECHAMENTO] float NULL,
    [VL_VALOPE] float NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);