CREATE TABLE [dbo].[SCHEMA_SYNC_RENAME_MAP] (
    [base_schema] sysname NOT NULL,
    [base_table] sysname NOT NULL,
    [old_col] sysname NOT NULL,
    [new_col] sysname NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_SCHEMA_SYNC_RENAME_MAP] PRIMARY KEY ([base_schema], [base_table], [old_col], [new_col])
);