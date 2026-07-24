CREATE TABLE [dbo].[django_admin_log] (
    [id] int IDENTITY(1,1) NOT NULL,
    [action_time] datetimeoffset(7) NOT NULL,
    [object_id] nvarchar(MAX) NULL,
    [object_repr] nvarchar(200) NOT NULL,
    [action_flag] smallint NOT NULL,
    [change_message] nvarchar(MAX) NOT NULL,
    [content_type_id] int NULL,
    [user_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_django_admin_log] PRIMARY KEY ([id]),
    CONSTRAINT [django_admin_log_action_flag_a8637d59_check] CHECK ([action_flag]>=(0))
);

CREATE INDEX [django_admin_log_content_type_id_c4bce8eb] ON [dbo].[django_admin_log] ([content_type_id]);

CREATE INDEX [django_admin_log_user_id_c564eba6] ON [dbo].[django_admin_log] ([user_id]);

ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [django_admin_log_content_type_id_c4bce8eb_fk_django_content_type_id] FOREIGN KEY ([content_type_id]) REFERENCES [dbo].[django_content_type] ([id]);

ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [django_admin_log_user_id_c564eba6_fk_auth_user_id] FOREIGN KEY ([user_id]) REFERENCES [dbo].[auth_user] ([id]);