CREATE TABLE [dbo].[score_category] (
    [id] int NOT NULL,
    [name] nvarchar(50) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_score_category] PRIMARY KEY ([id])
);