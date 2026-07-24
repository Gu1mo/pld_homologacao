CREATE TABLE [dbo].[ST_SWINGTRADE_BOVESPA] (
    [PREGAO] datetime NULL,
    [PREGAO_ANT] datetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [PAPEL] nvarchar(20) NULL,
    [QUANTIDADE] float NULL,
    [PRECO_COMPRA] float NULL,
    [PRECO_VENDA] float NULL,
    [RESULTADO] float NULL,
    [QTD_SWINGTRADE] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);