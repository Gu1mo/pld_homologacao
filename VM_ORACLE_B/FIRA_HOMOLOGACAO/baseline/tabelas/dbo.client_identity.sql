CREATE TABLE [dbo].[client_identity] (
    [client_identity] nvarchar(2048) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);