CREATE TABLE [dbo].[ST_TRANSFERENCIA_CUST] (
    [COD_CLI] int NULL,
    [DATA_MVTO] datetime2(7) NULL,
    [COD_NEG] varchar(12) NULL,
    [QTDE_MVTO] numeric(19,4) NULL,
    [DESC_HIST_MVTO] varchar(80) NULL,
    [COD_USUA_CONP] numeric(5,0) NULL,
    [COD_MVTO] numeric(3,0) NULL,
    [NAT_OPE] varchar(1) NULL,
    [TIPO_MVTO] varchar(4) NULL,
    [COD_ISIN] varchar(12) NULL,
    [TIPO_MERC] varchar(5) NULL,
    [COD_LOC] numeric(7,0) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);