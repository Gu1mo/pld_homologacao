CREATE TABLE [dbo].[ST_OPER_ORDENS] (
    [DT_DATORD] smalldatetime NULL,
    [NR_SEQORD] varchar(20) NULL,
    [CD_NEGOCIO] varchar(20) NULL,
    [CD_CLIENTE] int NOT NULL,
    [CD_NATOPE] char(2) NULL,
    [CD_CODUSU] int NULL,
    [NM_CLIENTE] varchar(MAX) NULL,
    [NM_EMIT_ORDEM] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);