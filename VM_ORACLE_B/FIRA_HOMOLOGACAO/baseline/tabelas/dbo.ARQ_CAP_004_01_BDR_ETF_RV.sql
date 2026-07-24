CREATE TABLE [dbo].[ARQ_CAP_004_01_BDR_ETF_RV] (
    [fundo] varchar(50) NULL,
    [ticker] varchar(50) NULL,
    [ticker_bdr] varchar(50) NULL,
    [isin] varchar(50) NULL,
    [isin_bdr] varchar(50) NULL,
    [paridade] varchar(50) NULL,
    [pais] varchar(50) NULL,
    [tipo_inv] varchar(50) NULL,
    [restricao_us_person] varchar(50) NULL,
    [banco_depositario] varchar(50) NULL,
    [bolsa_de_origem] varchar(50) NULL,
    [setor] varchar(50) NULL,
    [criado_em_utc] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [DT_CARGA] date NULL
);