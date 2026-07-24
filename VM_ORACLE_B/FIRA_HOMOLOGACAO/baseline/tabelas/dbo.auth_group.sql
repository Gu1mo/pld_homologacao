CREATE TABLE [dbo].[auth_group] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] nvarchar(150) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_group] PRIMARY KEY ([id])
);