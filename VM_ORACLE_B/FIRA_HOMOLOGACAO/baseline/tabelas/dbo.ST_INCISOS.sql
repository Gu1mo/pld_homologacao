CREATE TABLE [dbo].[ST_INCISOS] (
    [ID] int NULL,
    [Circular ] nvarchar(255) NULL,
    [Exigencia] nvarchar(255) NULL,
    [Inciso] nvarchar(255) NULL,
    [ALERTA FIRA] nvarchar(255) NULL,
    [DESCRIÇÃO] nvarchar(255) NULL,
    [ALERTA] nvarchar(255) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE UNIQUE INDEX [UX_ST_INCISOS_id] ON [dbo].[ST_INCISOS] ([ID]);