CREATE TABLE [dbo].[LogProcesso] (
    [logProcessoId] int NOT NULL,
    [processoId] int NOT NULL,
    [linhaId] int NOT NULL,
    [dataLog] datetime NOT NULL,
    [log] varchar(7500) NOT NULL,
    [indicaLogResumido] char(1) NOT NULL,
    [checklistId] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_LogProcesso] PRIMARY KEY ([logProcessoId], [processoId], [linhaId])
);

ALTER TABLE [dbo].[LogProcesso] ADD CONSTRAINT [LogProcesso_FK01] FOREIGN KEY ([processoId]) REFERENCES [dbo].[Processo] ([processoId]);