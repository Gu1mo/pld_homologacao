CREATE TABLE [dbo].[auth_user_user_permissions] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [user_id] int NOT NULL,
    [permission_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_user_user_permissions] PRIMARY KEY ([id])
);

CREATE INDEX [auth_user_user_permissions_permission_id_1fbb5f2c] ON [dbo].[auth_user_user_permissions] ([permission_id]);

CREATE INDEX [auth_user_user_permissions_user_id_a95ead1b] ON [dbo].[auth_user_user_permissions] ([user_id]);

CREATE UNIQUE INDEX [auth_user_user_permissions_user_id_permission_id_14a6b632_uniq] ON [dbo].[auth_user_user_permissions] ([user_id], [permission_id]);

ALTER TABLE [dbo].[auth_user_user_permissions] ADD CONSTRAINT [auth_user_user_permissions_permission_id_1fbb5f2c_fk_auth_permission_id] FOREIGN KEY ([permission_id]) REFERENCES [dbo].[auth_permission] ([id]);

ALTER TABLE [dbo].[auth_user_user_permissions] ADD CONSTRAINT [auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id] FOREIGN KEY ([user_id]) REFERENCES [dbo].[auth_user] ([id]);