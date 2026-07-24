CREATE TABLE [dbo].[ticket_ticket] (
    [id] bigint IDENTITY(1,1) NOT NULL,
    [uuid] varchar(300) NOT NULL,
    [year] int NOT NULL,
    [month] int NOT NULL,
    [cod_corretora] int NOT NULL,
    [status] nvarchar(255) NOT NULL,
    [datetime_created] datetime2(7) NULL,
    [datetime_updated] datetime2(7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_ticket_ticket] PRIMARY KEY ([id])
);