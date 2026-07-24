CREATE TABLE [dbo].[TSCDXPSJU_SFP] (
    [NUM_SEQ_CLIENTE] numeric(9,0) NULL,
    [VAL_CAPTL_SCIAL] numeric(17,2) NULL,
    [DATA_REFER_CAPTL_SCIAL] datetime2(7) NULL,
    [VAL_PATRM_LIQ] numeric(17,2) NULL,
    [DATA_REFER_PATRM_LIQ] datetime2(7) NULL,
    [VAL_CAPTL_GIRO] numeric(17,2) NULL,
    [DATA_REFER_CAPTL_GIRO] datetime2(7) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);