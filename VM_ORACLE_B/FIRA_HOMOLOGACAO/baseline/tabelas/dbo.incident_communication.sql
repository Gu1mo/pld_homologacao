CREATE TABLE [dbo].[incident_communication] (
    [incident_id] int NULL,
    [cvm_communication_date] date NULL,
    [bsm_communication_date] date NULL,
    [coaf_communication_date] date NULL,
    [adm_communication_date] date NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);