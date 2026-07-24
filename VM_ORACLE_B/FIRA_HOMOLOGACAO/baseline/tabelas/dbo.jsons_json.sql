CREATE TABLE [dbo].[jsons_json] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [uuid] varchar(300) NOT NULL,
    [date_generated] datetimeoffset(7) NOT NULL,
    [type] int NOT NULL,
    [datetime_created] datetimeoffset(7) NOT NULL,
    [datetime_updated] datetimeoffset(7) NOT NULL,
    [ticket_id] bigint NULL,
    [date_matriz] datetimeoffset(7) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_jsons_json] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[jsons_json] ADD CONSTRAINT [FK_jsons_json_ticket] FOREIGN KEY ([ticket_id]) REFERENCES [dbo].[ticket_ticket] ([id]);