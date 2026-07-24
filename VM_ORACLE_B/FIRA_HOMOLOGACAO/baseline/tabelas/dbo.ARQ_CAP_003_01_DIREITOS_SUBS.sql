CREATE TABLE [dbo].[ARQ_CAP_003_01_DIREITOS_SUBS] (
    [denom_soc] varchar(200) NULL,
    [nm_pregao] varchar(200) NULL,
    [isin] varchar(200) NULL,
    [cod_neg] varchar(200) NULL,
    [n_emiss] varchar(200) NULL,
    [classe] varchar(200) NULL,
    [tp_oferta] varchar(200) NULL,
    [dt_lib_prof] varchar(50) NULL,
    [dt_lib_qual] varchar(50) NULL,
    [dt_lib_var] varchar(50) NULL,
    [criado_em_utc] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [DT_CARGA] date NULL
);