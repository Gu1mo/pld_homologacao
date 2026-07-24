CREATE TABLE [dbo].[ST_TORNEG] (
    [HH_NEGOCIO] varchar(5) NULL,
    [CD_CONTRAPARTE] numeric(8,0) NULL,
    [TP_MERCADO] varchar(3) NULL,
    [CD_NEGOCIO] varchar(12) NULL,
    [CD_OPERA_MEGA] numeric(6,0) NULL,
    [FT_VALORIZACAO] numeric(15,5) NULL,
    [DT_SISTEMA] datetime2(7) NULL,
    [IN_AFTERM] varchar(1) NULL,
    [DT_PREGAO] datetime2(7) NULL,
    [CD_BOLSAMOV] varchar(2) NULL,
    [NR_NEGOCIO] numeric(9,0) NULL,
    [CD_NATOPE] char(1) NULL,
    [IN_LEILAO] char(1) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [TP_VCOTER] numeric(5,0) NULL,
    [NR_OFEMEGA] bigint NULL
);