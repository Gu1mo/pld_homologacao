CREATE TABLE [dbo].[score_others] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [name] nvarchar(200) NULL,
    [category_id] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_score_others] PRIMARY KEY ([id])
);