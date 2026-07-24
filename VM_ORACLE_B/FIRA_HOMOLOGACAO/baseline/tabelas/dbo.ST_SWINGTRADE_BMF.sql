CREATE TABLE [dbo].[ST_SWINGTRADE_BMF] (
    [PREGAO] smalldatetime NULL,
    [PREGAO_ANT] smalldatetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_COMMOD] char(3) NULL,
    [CD_SERIE] char(4) NULL,
    [QUANTIDADE] float NULL,
    [PRECO_COMPRA] float NULL,
    [PRECO_VENDA] float NULL,
    [RESULTADO] float NULL,
    [QTD_SWINGTRADE] int NOT NULL,
    [FINANCEIRO] float NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);