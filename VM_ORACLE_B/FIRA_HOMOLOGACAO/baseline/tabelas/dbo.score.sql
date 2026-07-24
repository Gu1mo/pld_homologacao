CREATE TABLE [dbo].[score] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [name] nvarchar(200) NULL,
    [category_id] int NULL,
    [value] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_score] PRIMARY KEY ([id])
);