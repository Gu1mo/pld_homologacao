CREATE TABLE [dbo].[ST_RESUMO_DIRETAS_BVSP] (
    [DT_PERIODO] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [QTD_DIRETAS] int NULL,
    [QTD_NEGOCIOS] int NULL,
    [PERC_TOT] float NULL,
    [CD_CLIENTE_PONTA] int NOT NULL,
    [QTD_DIRETAS_PONTA] int NULL,
    [PERC_ponta] float NULL,
    [DAYTRADE] varchar(3) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);