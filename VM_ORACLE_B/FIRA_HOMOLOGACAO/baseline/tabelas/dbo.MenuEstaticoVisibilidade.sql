CREATE TABLE [dbo].[MenuEstaticoVisibilidade] (
    [ID] int IDENTITY(1,1) NOT NULL,
    [CHAVE] nvarchar(150) NOT NULL,
    [ROTULO] nvarchar(150) NOT NULL,
    [ROTA] nvarchar(255) NULL,
    [CHAVE_PAI] nvarchar(150) NULL,
    [VISIVEL] bit NOT NULL DEFAULT ('1'),
    [INDICE] int NOT NULL,
    [CRIADO_EM] datetime2(7) NOT NULL DEFAULT (getdate()),
    [ATUALIZADO_EM] datetime2(7) NOT NULL DEFAULT (getdate()),
    CONSTRAINT [PK_MenuEstaticoVisibilidade] PRIMARY KEY ([ID])
);

CREATE UNIQUE INDEX [menuestaticovisibilidade_chave_unique] ON [dbo].[MenuEstaticoVisibilidade] ([CHAVE]);