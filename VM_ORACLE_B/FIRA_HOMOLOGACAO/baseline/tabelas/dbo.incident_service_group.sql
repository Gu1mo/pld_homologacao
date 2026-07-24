CREATE TABLE [dbo].[incident_service_group] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] varchar(100) NOT NULL,
    [status_id] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_service_group] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_service_group] ADD CONSTRAINT [FK_incident_statu_002] FOREIGN KEY ([status_id]) REFERENCES [dbo].[incident_status] ([id]);