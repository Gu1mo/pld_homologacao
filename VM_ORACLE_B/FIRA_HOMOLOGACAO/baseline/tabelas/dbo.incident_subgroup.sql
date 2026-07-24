CREATE TABLE [dbo].[incident_subgroup] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [name] nvarchar(1000) NOT NULL,
    [group_id] bigint NOT NULL,
    [status_id] int NOT NULL,
    [subparagraph_id] bigint NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_subgroup] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[incident_subgroup] ADD CONSTRAINT [FK_incident_subgroup_incident_group] FOREIGN KEY ([group_id]) REFERENCES [dbo].[incident_group] ([id]);

ALTER TABLE [dbo].[incident_subgroup] ADD CONSTRAINT [FK_incident_subgroup_incident_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[incident_status] ([id]);

ALTER TABLE [dbo].[incident_subgroup] ADD CONSTRAINT [FK_incident_subpa_002] FOREIGN KEY ([subparagraph_id]) REFERENCES [dbo].[incident_article_subparagraph] ([id]);