CREATE TABLE [dbo].[AUD_SCHEMA_SYNC_V2] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [batch_id] uniqueidentifier NOT NULL,
    [dt_exec] datetime2(0) NOT NULL DEFAULT (sysdatetime()),
    [base_table] sysname NOT NULL,
    [dst_table] sysname NOT NULL,
    [action_type] varchar(50) NOT NULL,
    [object_name] sysname NULL,
    [details] nvarchar(MAX) NULL,
    [sql_text] nvarchar(MAX) NULL,
    [success] bit NOT NULL,
    [error_message] nvarchar(MAX) NULL,
    CONSTRAINT [PK_AUD_SCHEMA_SYNC_V2] PRIMARY KEY ([id])
);