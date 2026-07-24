CREATE TABLE [dbo].[incident_columns] (
    [id] int IDENTITY(1,1) NOT NULL,
    [title] nvarchar(1000) NOT NULL,
    [status_id] int NOT NULL,
    [order_status] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_columns] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_columns] ADD CONSTRAINT [FK_incident_columns_incident_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[incident_status] ([id]);