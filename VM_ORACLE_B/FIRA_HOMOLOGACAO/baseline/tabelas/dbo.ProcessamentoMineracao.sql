CREATE TABLE [dbo].[ProcessamentoMineracao] (
    [id] int IDENTITY(1,1) NOT NULL,
    [id_matriz] varchar(50) NULL,
    [data] smalldatetime NULL,
    [qtd_processada] bigint NULL,
    [status] varchar(50) NULL,
    [mes] bigint NULL,
    [ano] bigint NULL,
    [qtd] bigint NULL,
    [responsavel] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ProcessamentoMineracao] PRIMARY KEY ([id])
);