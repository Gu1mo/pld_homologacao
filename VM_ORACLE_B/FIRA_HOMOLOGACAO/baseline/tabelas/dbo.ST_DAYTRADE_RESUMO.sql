CREATE TABLE [dbo].[ST_DAYTRADE_RESUMO] (
    [CD_CLIENTE_COMPROU] int NULL,
    [VL_COMPRA] float NULL,
    [VL_VENDA] float NULL,
    [VL_FINANC] float NULL,
    [DT_PREGAO_COMPROU] datetime NOT NULL,
    [QT_CONTRAPARTES] int NULL,
    [DT_PRIMEIRA_OPER] smalldatetime NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);