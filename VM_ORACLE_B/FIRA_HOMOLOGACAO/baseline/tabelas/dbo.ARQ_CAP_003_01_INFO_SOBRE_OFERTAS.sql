CREATE TABLE [dbo].[ARQ_CAP_003_01_INFO_SOBRE_OFERTAS] (
    [denom_soc] varchar(255) NULL,
    [nm_pregao] varchar(255) NULL,
    [isin] varchar(50) NULL,
    [cod_neg] varchar(50) NULL,
    [n_emiss] varchar(50) NULL,
    [classe] varchar(50) NULL,
    [tp_oferta] varchar(50) NULL,
    [dt_encerramento] date NULL,
    [dt_lib_prof] date NULL,
    [dt_lib_qual] date NULL,
    [dt_lib_var] date NULL,
    [dt_entrega] date NULL,
    [criado_em_utc] date NULL DEFAULT (getdate()),
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [DT_CARGA] date NULL
);