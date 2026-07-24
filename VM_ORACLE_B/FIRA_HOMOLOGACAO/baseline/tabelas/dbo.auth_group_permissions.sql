CREATE TABLE [dbo].[auth_group_permissions] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [group_id] int NOT NULL,
    [permission_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_group_permissions] PRIMARY KEY ([id])
);

CREATE INDEX [auth_group_permissions_group_id_b120cbf9] ON [dbo].[auth_group_permissions] ([group_id]);

CREATE UNIQUE INDEX [auth_group_permissions_group_id_permission_id_0cd325b0_uniq] ON [dbo].[auth_group_permissions] ([group_id], [permission_id]);

CREATE INDEX [auth_group_permissions_permission_id_84c5c92e] ON [dbo].[auth_group_permissions] ([permission_id]);

ALTER TABLE [dbo].[auth_group_permissions] ADD CONSTRAINT [auth_group_permissions_group_id_b120cbf9_fk_auth_group_id] FOREIGN KEY ([group_id]) REFERENCES [dbo].[auth_group] ([id]);

ALTER TABLE [dbo].[auth_group_permissions] ADD CONSTRAINT [auth_group_permissions_permission_id_84c5c92e_fk_auth_permission_id] FOREIGN KEY ([permission_id]) REFERENCES [dbo].[auth_permission] ([id]);