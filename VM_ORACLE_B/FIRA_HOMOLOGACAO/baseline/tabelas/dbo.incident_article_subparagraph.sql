CREATE TABLE [dbo].[incident_article_subparagraph] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [subparagraph] varchar(800) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_incident_article_subparagraph] PRIMARY KEY ([id])
);