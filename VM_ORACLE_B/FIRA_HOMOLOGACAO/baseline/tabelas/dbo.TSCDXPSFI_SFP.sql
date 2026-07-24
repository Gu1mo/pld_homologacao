CREATE TABLE [dbo].[TSCDXPSFI_SFP] (
    [NUM_SEQ_CLIENTE] int NULL,
    [VAL_RENDA_ANUAL] decimal(32,5) NULL,
    [DATA_REFER_RENDA_ANUAL] datetime NULL,
    [VAL_SITU_PATRM] decimal(32,5) NULL,
    [DATA_REFER_SITU_PATRM] datetime NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);