CREATE TABLE [dbo].[ST_MESA_BVSP] (
    [CD_CLIENTE] int NOT NULL,
    [DT_PERIODO] smalldatetime NOT NULL,
    [NR_NEGOCIO] int NOT NULL,
    [CD_NATOPE] char(1) NOT NULL,
    [CD_PAPEL] varchar(12) NOT NULL,
    [NR_SEQORD] int NOT NULL,
    [CD_CONTRAPARTE] numeric(5,0) NULL,
    [CD_ASSESSOR] int NULL,
    [HH_NEGOCIO] varchar(5) NULL,
    [QT_NEGOCIO] bigint NULL,
    [VL_NEGOCIO] float NULL,
    [VL_TOTNEG] float NULL,
    [VL_CORTOT_ORI] float NULL,
    [CD_OPERADOR] int NULL,
    [DS_OPERADOR] varchar(160) NULL,
    [NM_CORRET] varchar(400) NULL,
    [TP_PESSOA] char(2) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [NM_CLIENTE] varchar(400) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ST_MESA_BVSP] PRIMARY KEY ([CD_CLIENTE], [DT_PERIODO], [NR_NEGOCIO], [CD_NATOPE], [CD_PAPEL], [NR_SEQORD])
);

CREATE INDEX [IDX001_ST_MESA_BVSP] ON [dbo].[ST_MESA_BVSP] ([DT_PERIODO]);