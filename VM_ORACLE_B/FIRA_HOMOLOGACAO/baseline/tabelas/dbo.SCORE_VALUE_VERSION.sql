CREATE TABLE [dbo].[SCORE_VALUE_VERSION] (
    [version_id] bigint IDENTITY(1,1) NOT NULL,
    [score_id] bigint NOT NULL,
    [value] int NOT NULL,
    [effective_from] datetime2(7) NOT NULL,
    [effective_to] datetime2(7) NULL,
    [changed_at] datetime2(7) NOT NULL,
    [changed_by] sysname NULL DEFAULT (suser_sname()),
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_SCORE_VALUE_VERSION] PRIMARY KEY ([version_id]),
    CONSTRAINT [CK_SVV_Range] CHECK ([effective_to] IS NULL OR [effective_to]>[effective_from])
);

CREATE INDEX [IX_SVV_score_from] ON [dbo].[SCORE_VALUE_VERSION] ([score_id], [effective_from] DESC);

CREATE INDEX [IX_SVV_score_to] ON [dbo].[SCORE_VALUE_VERSION] ([score_id], [effective_to]);

ALTER TABLE [dbo].[SCORE_VALUE_VERSION] ADD CONSTRAINT [FK_SVV_SCORE] FOREIGN KEY ([score_id]) REFERENCES [dbo].[score] ([id]);