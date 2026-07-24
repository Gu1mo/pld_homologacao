CREATE TABLE [dbo].[incident_subgroup_model] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [name] nvarchar(1000) NOT NULL,
    [group_id] bigint NOT NULL,
    [status_id] int NOT NULL,
    [subparagraph_id] bigint NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);