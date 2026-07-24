CREATE TABLE [dbo].[ListaAcoes] (
    [TICKER] varchar(4) NULL,
    [CNPJ] varchar(20) NULL,
    [RAZAO_SOCIAL] varchar(800) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL
);

CREATE UNIQUE INDEX [UX_ListaAcoes_TICKER] ON [dbo].[ListaAcoes] ([TICKER]);