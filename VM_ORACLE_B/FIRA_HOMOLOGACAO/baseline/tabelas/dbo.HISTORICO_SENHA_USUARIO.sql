CREATE TABLE [dbo].[HISTORICO_SENHA_USUARIO] (
    [id] int IDENTITY(1,1) NOT NULL,
    [cd_usuario] int NULL,
    [usuario] varchar(100) NULL,
    [senha] nvarchar(260) NULL,
    [CHAVESENHA] varchar(100) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);