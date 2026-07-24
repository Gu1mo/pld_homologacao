CREATE TABLE [dbo].[incident_status] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] nvarchar(100) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_status] PRIMARY KEY ([id])
);