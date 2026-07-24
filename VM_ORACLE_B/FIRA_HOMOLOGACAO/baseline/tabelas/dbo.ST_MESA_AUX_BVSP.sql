CREATE TABLE [dbo].[ST_MESA_AUX_BVSP] (
    [CD_ANOMES] int NOT NULL,
    [CD_CLIENTE] int NOT NULL,
    [QTD_C] bigint NULL,
    [QTD_V] bigint NULL,
    [QTD] bigint NULL,
    [CORRETAGEM] float NULL,
    [VOLUME_COMPRA] float NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ST_MESA_AUX_BVSP] PRIMARY KEY ([CD_ANOMES], [CD_CLIENTE])
);