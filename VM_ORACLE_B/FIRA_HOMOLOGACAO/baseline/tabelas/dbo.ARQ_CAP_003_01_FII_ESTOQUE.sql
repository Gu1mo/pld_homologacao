CREATE TABLE [dbo].[ARQ_CAP_003_01_FII_ESTOQUE] (
    [denom_soc] varchar(356) NULL,
    [nm_pregao] varchar(50) NULL,
    [cod_neg] varchar(50) NULL,
    [isin] varchar(50) NULL,
    [classe] varchar(50) NULL,
    [pub_alvo] varchar(50) NULL,
    [dt_entrega] date NULL,
    [criado_em_utc] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);