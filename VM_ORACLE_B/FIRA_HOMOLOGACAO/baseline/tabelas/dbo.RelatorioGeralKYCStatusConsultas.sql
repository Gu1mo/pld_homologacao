CREATE TABLE [dbo].[RelatorioGeralKYCStatusConsultas] (
    [id_requisicao] int NULL,
    [processos] bit NULL,
    [noticias] bit NULL,
    [pad] bit NULL,
    [pas] bit NULL,
    [rfb] int NULL,
    [listas] bit NULL,
    [pad_bsm] bit NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);