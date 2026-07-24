CREATE TABLE [dbo].[TSCTPINVESTIDOR] (
    [TP_INVESTIDOR] numeric(5,0) NOT NULL,
    [IN_IRRF_CORRET] char(1) NOT NULL,
    [DS_INVESTIDOR] varchar(250) NOT NULL,
    [PC_SFP] numeric(3,0) NOT NULL,
    [TP_CLIENTE] numeric(2,0) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);