CREATE TABLE [dbo].[ST_CUSTODIA_BMF] (
    [DT_DATMOV] datetime NOT NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_COMMOD] nchar(13) NULL,
    [CD_SERIE] nchar(14) NULL,
    [CD_MERCAD] nchar(13) NULL,
    [VL_DIA_ATU] numeric(15,3) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);