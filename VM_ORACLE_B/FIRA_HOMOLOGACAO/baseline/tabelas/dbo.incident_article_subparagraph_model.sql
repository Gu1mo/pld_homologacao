CREATE TABLE [dbo].[incident_article_subparagraph_model] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [subparagraph] varchar(800) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);