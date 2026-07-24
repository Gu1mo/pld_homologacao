CREATE TABLE [dbo].[TSCASSES] (
    [CD_ASSESSOR] int NULL,
    [NM_ASSESSOR] varchar(300) NULL,
    [NM_RESU_ASSES] varchar(300) NULL,
    [PC_ADIANTAMENTO] numeric(6,3) NULL,
    [IN_SITUAC] char(2) NULL,
    [CD_EMPRESA] int NULL,
    [CD_USUARIO] int NULL,
    [TP_OCORRENCIA] varchar(130) NULL,
    [CD_MUNICIPIO] int NULL,
    [NM_E_MAIL] nvarchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);