CREATE TABLE [dbo].[auth_permission] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] nvarchar(255) NOT NULL,
    [content_type_id] int NOT NULL,
    [codename] nvarchar(100) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_permission] PRIMARY KEY ([id])
);

CREATE INDEX [auth_permission_content_type_id_2f476e4b] ON [dbo].[auth_permission] ([content_type_id]);

CREATE UNIQUE INDEX [auth_permission_content_type_id_codename_01ab375a_uniq] ON [dbo].[auth_permission] ([content_type_id], [codename]);

ALTER TABLE [dbo].[auth_permission] ADD CONSTRAINT [auth_permission_content_type_id_2f476e4b_fk_django_content_type_id] FOREIGN KEY ([content_type_id]) REFERENCES [dbo].[django_content_type] ([id]);