CREATE TABLE [dbo].[incident_event] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [event] nvarchar(MAX) NOT NULL,
    [state_id] bigint NULL,
    [incident_id] bigint NOT NULL,
    [author_id] bigint NOT NULL,
    [at_date] smalldatetime NOT NULL,
    [old_assignee_id] bigint NULL,
    [new_assignee_id] bigint NULL,
    [article_subparagraph_group] varchar(500) NULL,
    [id_processamento] bigint NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_event] PRIMARY KEY ([id])
);