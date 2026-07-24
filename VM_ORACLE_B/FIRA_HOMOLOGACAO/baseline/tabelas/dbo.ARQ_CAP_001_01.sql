CREATE TABLE [dbo].[ARQ_CAP_001_01] (
    [nm_pregao] varchar(200) NULL,
    [denom_soc] varchar(200) NULL,
    [seg_neg] varchar(20) NULL,
    [cod_neg] varchar(20) NULL,
    [val_mob] varchar(50) NULL,
    [rito] varchar(20) NULL,
    [dt_ini_neg] date NULL,
    [dt_lib_prof] date NULL,
    [dt_lib_qual] date NULL,
    [dt_lib_var] date NULL,
    [dt_atualizacao] date NULL,
    [criado_em_utc] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);