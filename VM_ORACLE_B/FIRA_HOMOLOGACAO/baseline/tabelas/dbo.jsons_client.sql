CREATE TABLE [dbo].[jsons_client] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [uuid] varchar(300) NOT NULL,
    [data] nvarchar(MAX) NOT NULL,
    [json_id] bigint NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_jsons_client] PRIMARY KEY ([id])
);

CREATE INDEX [ID001_jsons_client] ON [dbo].[jsons_client] ([json_id]);

ALTER TABLE [dbo].[jsons_client] ADD CONSTRAINT [FK_jsons_client_json] FOREIGN KEY ([json_id]) REFERENCES [dbo].[jsons_json] ([id]);