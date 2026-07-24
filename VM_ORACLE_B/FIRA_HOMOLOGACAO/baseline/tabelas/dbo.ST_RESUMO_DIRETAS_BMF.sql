CREATE TABLE [dbo].[ST_RESUMO_DIRETAS_BMF] (
    [dt_negocio] smalldatetime NULL,
    [cd_cliente] int NOT NULL,
    [qtd_diretas] int NULL,
    [qtd_negocios] int NULL,
    [PERC_TOT] float NULL,
    [CD_CLIENTE_PONTA] int NULL,
    [QTD_DIRETAS_PONTA] int NULL,
    [PERC_PONTA] float NULL,
    [IN_DAYTRADE_CONTRAPARTE] char(3) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);