CREATE TABLE [dbo].[GrupoPerfilUsuario] (
    [id] int IDENTITY(1,1) NOT NULL,
    [grupo] varchar(50) NULL,
    [perfil] varchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_GrupoPerfilUsuario] PRIMARY KEY ([id])
);