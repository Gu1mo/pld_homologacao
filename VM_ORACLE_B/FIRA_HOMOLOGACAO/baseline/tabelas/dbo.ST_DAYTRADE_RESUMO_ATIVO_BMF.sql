CREATE TABLE [dbo].[ST_DAYTRADE_RESUMO_ATIVO_BMF] (
    [CD_CLIENTE] int NOT NULL,
    [CD_COMMOD] varchar(10) NULL,
    [CD_SERIE] varchar(10) NULL,
    [VL_COMPRA] float NULL,
    [VL_VENDA] float NULL,
    [VL_FINANC] float NULL,
    [DT_PREGAO_COMPROU] datetime NULL,
    [QT_CONTRAPARTES] int NULL,
    [DT_PRIMEIRA_OPER] smalldatetime NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);