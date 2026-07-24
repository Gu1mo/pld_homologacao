CREATE TABLE [dbo].[auth_user_groups] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [user_id] int NOT NULL,
    [group_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_user_groups] PRIMARY KEY ([id])
);

CREATE INDEX [auth_user_groups_group_id_97559544] ON [dbo].[auth_user_groups] ([group_id]);

CREATE INDEX [auth_user_groups_user_id_6a12ed8b] ON [dbo].[auth_user_groups] ([user_id]);

CREATE UNIQUE INDEX [auth_user_groups_user_id_group_id_94350c0c_uniq] ON [dbo].[auth_user_groups] ([user_id], [group_id]);

ALTER TABLE [dbo].[auth_user_groups] ADD CONSTRAINT [auth_user_groups_group_id_97559544_fk_auth_group_id] FOREIGN KEY ([group_id]) REFERENCES [dbo].[auth_group] ([id]);

ALTER TABLE [dbo].[auth_user_groups] ADD CONSTRAINT [auth_user_groups_user_id_6a12ed8b_fk_auth_user_id] FOREIGN KEY ([user_id]) REFERENCES [dbo].[auth_user] ([id]);