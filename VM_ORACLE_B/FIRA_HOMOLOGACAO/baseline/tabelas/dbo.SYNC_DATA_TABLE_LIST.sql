CREATE TABLE [dbo].[SYNC_DATA_TABLE_LIST] (
    [schema_name] sysname NOT NULL DEFAULT ('dbo'),
    [table_name] sysname NOT NULL,
    [sync_order] int NOT NULL,
    [is_enabled] bit NOT NULL DEFAULT ((1)),
    [allow_delete] bit NOT NULL DEFAULT ((0)),
    [copy_identity] bit NOT NULL DEFAULT ((0)),
    [notes] nvarchar(200) NULL,
    CONSTRAINT [PK_SYNC_DATA_TABLE_LIST] PRIMARY KEY ([schema_name], [table_name])
);