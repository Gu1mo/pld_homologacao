CREATE TABLE [dbo].[audit_risk] (
    [id] int IDENTITY(1,1) NOT NULL,
    [dadosModificados] text NULL,
    [date] datetime NULL,
    [userId] varchar(255) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_audit_risk] PRIMARY KEY ([id])
);