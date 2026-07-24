CREATE TABLE [dbo].[BENEFICIARIOS] (
    [ID] int NULL,
    [CPFCNPJ] varchar(50) NULL,
    [NOME] nvarchar(MAX) NULL,
    [DATA_CRIACAO] smalldatetime NULL,
    [DATA_ENCERRAMENTO] smalldatetime NULL,
    [VISIVEL] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);