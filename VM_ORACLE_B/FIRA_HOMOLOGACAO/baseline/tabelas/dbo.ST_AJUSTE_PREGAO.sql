CREATE TABLE [dbo].[ST_AJUSTE_PREGAO] (
    [DT_PREGAO] datetime2(7) NULL,
    [CD_COMMOD] nvarchar(60) NULL,
    [CD_SERIE] nvarchar(15) NULL,
    [CD_NEGOCIO] nvarchar(68) NULL,
    [PRECO_AJUTE_ANT] numeric(9,2) NULL,
    [PRECO_AJUSTE_ATUAL] numeric(9,2) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);