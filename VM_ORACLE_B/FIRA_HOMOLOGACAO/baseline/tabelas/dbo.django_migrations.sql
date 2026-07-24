CREATE TABLE [dbo].[django_migrations] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [app] nvarchar(255) NOT NULL,
    [name] nvarchar(255) NOT NULL,
    [applied] datetimeoffset(7) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_django_migrations] PRIMARY KEY ([id])
);