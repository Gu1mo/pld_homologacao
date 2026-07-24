CREATE TABLE [dbo].[score_levels] (
    [id] int IDENTITY(1,1) NOT NULL,
    [titulo] nvarchar(1000) NULL,
    [ativo] bit NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_score_levels] PRIMARY KEY ([id])
);