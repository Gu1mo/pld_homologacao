CREATE TABLE [dbo].[audit_login] (
    [id] int IDENTITY(1,1) NOT NULL,
    [user] nvarchar(MAX) NULL,
    [date] smalldatetime NULL,
    [ip_address] varchar(128) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_audit_login] PRIMARY KEY ([id])
);