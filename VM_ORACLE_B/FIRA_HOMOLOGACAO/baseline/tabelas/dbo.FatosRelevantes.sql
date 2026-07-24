CREATE TABLE [dbo].[FatosRelevantes] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Empresa] varchar(300) NOT NULL,
    [FatoRelevante] nvarchar(1000) NOT NULL,
    [Data] date NULL,
    [Ativo] varchar(4) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    [dt_carga] date NULL,
    CONSTRAINT [PK_FatosRelevantes] PRIMARY KEY ([Id])
);