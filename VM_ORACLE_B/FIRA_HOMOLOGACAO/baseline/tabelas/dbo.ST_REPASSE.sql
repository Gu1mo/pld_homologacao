CREATE TABLE [dbo].[ST_REPASSE] (
    [DT_PREGAO] datetime2(7) NULL,
    [CD_CLIENTE] int NOT NULL,
    [NR_NEGOCIO] numeric(10,0) NULL,
    [CD_NATOPE] nvarchar(2) NULL,
    [CD_COMMOD] nvarchar(60) NULL,
    [CD_SERIE] nvarchar(8) NULL,
    [CD_NEGOCIO] nvarchar(40) NULL,
    [IN_INT_REPASSE] nvarchar(2) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);