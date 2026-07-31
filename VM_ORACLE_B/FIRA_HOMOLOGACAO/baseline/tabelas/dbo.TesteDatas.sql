CREATE TABLE [dbo].[TesteDatas] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [DataInicio] datetime2(0) NOT NULL,
    [DataFim] datetime2(0) NOT NULL,
    [id_teste] int NULL,
    CONSTRAINT [PK_TesteDatas] PRIMARY KEY ([Id])
);