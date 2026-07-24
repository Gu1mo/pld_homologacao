CREATE TABLE [dbo].[AUD_SCHEMA_SYNC_PADRAO_AUTO] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [batch_id] uniqueidentifier NOT NULL,
    [dt_exec] datetime2(0) NOT NULL DEFAULT (sysdatetime()),
    [src_table] sysname NOT NULL,
    [dst_table] sysname NOT NULL,
    [action_type] varchar(40) NOT NULL,
    [object_name] sysname NULL,
    [sql_text] nvarchar(MAX) NULL,
    [success] bit NOT NULL,
    [error_message] nvarchar(MAX) NULL,
    CONSTRAINT [PK_AUD_SCHEMA_SYNC_PADRAO_AUTO] PRIMARY KEY ([id])
);