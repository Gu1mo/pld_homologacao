CREATE TABLE [dbo].[CarteiraIndiceBovespa] (
    [Codigo] varchar(MAX) NULL,
    [Acao] varchar(MAX) NULL,
    [Tipo] varchar(MAX) NULL,
    [QtdTeorica] varchar(MAX) NULL,
    [Parte] varchar(MAX) NULL,
    [Data] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);