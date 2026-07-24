CREATE TABLE [dbo].[ST_SALDO] (
    [CD_CLIENTE] int NOT NULL,
    [NM_CLIENTE] varchar(400) NULL,
    [VL_DISPONIVEL] numeric(15,2) NULL,
    [IN_CONTA_INV] char(1) NOT NULL,
    [DATA] date NULL,
    [CD_ASSESSOR] numeric(5,0) NOT NULL,
    [NM_ASSESSOR] varchar(60) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);