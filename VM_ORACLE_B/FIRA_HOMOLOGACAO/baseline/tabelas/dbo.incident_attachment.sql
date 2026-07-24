CREATE TABLE [dbo].[incident_attachment] (
    [id] int IDENTITY(1,1) NOT NULL,
    [content] varchar(MAX) NOT NULL,
    [name] varchar(1000) NOT NULL,
    [type] varchar(100) NOT NULL,
    [size] int NOT NULL,
    [incident_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_attachment] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_attachment] ADD CONSTRAINT [FK_incident_incid_001] FOREIGN KEY ([incident_id]) REFERENCES [dbo].[incident] ([id]);