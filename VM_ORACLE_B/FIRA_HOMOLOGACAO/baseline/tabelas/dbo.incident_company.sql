CREATE TABLE [dbo].[incident_company] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] varchar(100) NOT NULL,
    [status_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_company] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_company] ADD CONSTRAINT [FK_incident_statu_001] FOREIGN KEY ([status_id]) REFERENCES [dbo].[incident_status] ([id]);