CREATE TABLE [dbo].[incident_area] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [name] nvarchar(1000) NOT NULL,
    [email] nvarchar(1000) NOT NULL,
    [status_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_area] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_area] ADD CONSTRAINT [FK_incident_area_incident_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[incident_status] ([id]);