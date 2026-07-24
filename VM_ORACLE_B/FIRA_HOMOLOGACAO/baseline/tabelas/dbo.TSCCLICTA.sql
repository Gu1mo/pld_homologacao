CREATE TABLE [dbo].[TSCCLICTA] (
    [CD_CLIENTE] int NULL,
    [CD_BANCO] nvarchar(18) NULL,
    [CD_AGENCIA] nvarchar(15) NULL,
    [NR_CONTA] nvarchar(13) NULL,
    [DV_CONTA] nchar(12) NULL,
    [IN_PRINCIPAL] nchar(10) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);