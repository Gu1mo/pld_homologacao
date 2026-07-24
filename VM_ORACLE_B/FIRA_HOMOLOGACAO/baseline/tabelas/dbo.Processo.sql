CREATE TABLE [dbo].[Processo] (
    [processoId] int NOT NULL,
    [descricaoProcesso] varchar(50) NULL,
    [estaAtivo] char(1) NULL,
    [logProcessoId] int NULL,
    [tipoProcessoId] int NULL,
    [dataUltimaExecucao] datetime NULL,
    [dataAtualizacao] datetime NULL,
    [bancoDeDadosId] smallint NOT NULL,
    [sqlScript] varchar(MAX) NULL,
    [Visivel] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_Processo] PRIMARY KEY ([processoId])
);