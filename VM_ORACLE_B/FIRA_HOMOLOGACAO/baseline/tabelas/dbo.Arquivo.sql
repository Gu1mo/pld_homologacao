CREATE TABLE [dbo].[Arquivo] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Ocorrencia_Id] int NOT NULL,
    [Evento_Indice] int NOT NULL,
    [UltimaModificacao] int NULL,
    [DtUltimaModificacao] smalldatetime NULL,
    [Nome] nvarchar(MAX) NULL,
    [Tamanho] int NULL,
    [Tipo] nvarchar(MAX) NULL,
    [Arquivo] varbinary(1) NULL,
    [WebkitRelativePAth] nvarchar(MAX) NULL,
    [CaminhoServidor] nvarchar(MAX) NULL,
    [Visivel] bit NULL,
    [SomenteLeitura] bit NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_Arquivo] PRIMARY KEY ([Id])
);