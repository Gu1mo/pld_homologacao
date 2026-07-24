CREATE TABLE [dbo].[funcionarios] (
    [Codigo] int NULL,
    [NMCLIENTE] varchar(255) NULL,
    [CPFCNPJ] varchar(30) NULL,
    [dt_importacao] smalldatetime NULL DEFAULT (getdate()),
    [risco_inicial] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);