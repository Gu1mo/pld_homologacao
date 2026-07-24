CREATE TABLE [dbo].[ST_RELATORIO_MONEYPASS] (
    [ANOMES] int NULL,
    [CD_CLIENTE_1] int NULL,
    [CD_CLIENTE_2] int NULL,
    [CD_PAPEL] varchar(50) NULL,
    [QUANTIDADE] numeric(38,2) NULL,
    [RESULTADO] float NULL,
    [ASSERTIVIDADE] numeric(19,7) NULL,
    [CONCENTRACAO] numeric(19,7) NULL,
    [INTENCIONALIDADE] numeric(19,7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);