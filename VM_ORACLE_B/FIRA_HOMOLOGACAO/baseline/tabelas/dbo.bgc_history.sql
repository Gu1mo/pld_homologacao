CREATE TABLE [dbo].[bgc_history] (
    [id] int IDENTITY(1,1) NOT NULL,
    [ficha_limpa_request_id] int NULL,
    [status] varchar(32) NOT NULL,
    [service] varchar(128) NOT NULL,
    [name] varchar(128) NULL,
    [document] varchar(64) NULL,
    [dob] date NULL,
    [result] int NOT NULL,
    [request_date] datetime NOT NULL,
    [user_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_bgc_history] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[bgc_history] ADD CONSTRAINT [FK__bgc_histo__user___609E05C5] FOREIGN KEY ([user_id]) REFERENCES [dbo].[UsuarioPortal] ([Id]);