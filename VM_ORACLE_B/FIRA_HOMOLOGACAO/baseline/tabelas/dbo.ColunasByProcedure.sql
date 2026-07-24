CREATE TABLE [dbo].[ColunasByProcedure] (
    [ORDEM] int NULL,
    [ROTULO] varchar(200) NOT NULL,
    [NOME] varchar(200) NOT NULL,
    [PROCEDUREORIGEM] varchar(200) NOT NULL,
    [MASCARA] varchar(MAX) NULL,
    [TIPO] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE UNIQUE INDEX [UX_ColunasByProcedure_Procedure_Ordem] ON [dbo].[ColunasByProcedure] ([PROCEDUREORIGEM], [ORDEM]);