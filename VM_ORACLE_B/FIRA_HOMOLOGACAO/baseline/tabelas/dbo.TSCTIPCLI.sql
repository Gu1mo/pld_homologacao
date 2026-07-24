CREATE TABLE [dbo].[TSCTIPCLI] (
    [TP_CLIENTE] numeric(2,0) NOT NULL,
    [DS_TIPO_CLIENTE] nvarchar(40) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);