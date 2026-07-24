CREATE TABLE [dbo].[ST_PERFIL_CADASTRO] (
    [CLASS_RISCO] int NULL,
    [TP_CLIENTE] varchar(10) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [DT_FIRA] varchar(23) NULL DEFAULT (getdate())
);