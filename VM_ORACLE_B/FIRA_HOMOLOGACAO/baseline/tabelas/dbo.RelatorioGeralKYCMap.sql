CREATE TABLE [dbo].[RelatorioGeralKYCMap] (
    [IdRequisicaoRelatorioGeral] int NULL,
    [IdRequisicaoProcessos] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);