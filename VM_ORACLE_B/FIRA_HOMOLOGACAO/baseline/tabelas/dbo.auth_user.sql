CREATE TABLE [dbo].[auth_user] (
    [id] int IDENTITY(1,1) NOT NULL,
    [password] nvarchar(128) NOT NULL,
    [last_login] datetimeoffset(7) NULL,
    [is_superuser] bit NOT NULL,
    [username] nvarchar(150) NOT NULL,
    [first_name] nvarchar(150) NOT NULL,
    [last_name] nvarchar(150) NOT NULL,
    [email] nvarchar(254) NOT NULL,
    [is_staff] bit NOT NULL,
    [is_active] bit NOT NULL,
    [date_joined] datetimeoffset(7) NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_auth_user] PRIMARY KEY ([id])
);