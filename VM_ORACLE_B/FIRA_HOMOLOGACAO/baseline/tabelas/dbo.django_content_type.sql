CREATE TABLE [dbo].[django_content_type] (
    [id] int IDENTITY(1,1) NOT NULL,
    [app_label] nvarchar(100) NOT NULL,
    [model] nvarchar(100) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_django_content_type] PRIMARY KEY ([id])
);

CREATE UNIQUE INDEX [django_content_type_app_label_model_76bd3d3b_uniq] ON [dbo].[django_content_type] ([app_label], [model]);