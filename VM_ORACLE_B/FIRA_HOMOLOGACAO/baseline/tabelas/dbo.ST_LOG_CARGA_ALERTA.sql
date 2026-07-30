CREATE TABLE [dbo].[ST_LOG_CARGA_ALERTA] (
    [IDLOG] int IDENTITY(1,1) NOT NULL,
    [IDPROCESSO] int NOT NULL,
    [PROCESSO] varchar(255) NULL,
    [DTCARGA] date NULL,
    [DTINICIO] datetime NULL,
    [DTFIM] datetime NULL,
    [STATUS] varchar(20) NULL,
    [TEMPO_EXECUCAO] time(7) NULL,
    [ERRO] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);