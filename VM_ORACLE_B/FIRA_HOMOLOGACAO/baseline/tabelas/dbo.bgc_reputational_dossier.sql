CREATE TABLE [dbo].[bgc_reputational_dossier] (
    [id] int IDENTITY(1,1) NOT NULL,
    [ficha_limpa_reputational_dossier_id] int NULL,
    [status] varchar(32) NOT NULL,
    [risk] varchar(32) NULL,
    [name] varchar(128) NULL,
    [document] varchar(64) NULL,
    [country] varchar(128) NULL,
    [city] varchar(128) NULL,
    [dob] date NULL,
    [watch_lists] varchar(MAX) NULL,
    [territorial_watch_lists] varchar(MAX) NULL,
    [proceedings] varchar(MAX) NULL,
    [bsm_pad] varchar(MAX) NULL,
    [cvm_pas] varchar(MAX) NULL,
    [news] varchar(MAX) NULL,
    [rf] varchar(MAX) NULL,
    [started_at] datetime NOT NULL,
    [finished_at] datetime NULL,
    [user_id] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_bgc_reputational_dossier] PRIMARY KEY ([id])
);

ALTER TABLE [dbo].[bgc_reputational_dossier] ADD CONSTRAINT [FK__bgc_reput__user___637A7270] FOREIGN KEY ([user_id]) REFERENCES [dbo].[UsuarioPortal] ([Id]);