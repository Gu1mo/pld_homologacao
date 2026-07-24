CREATE TABLE [dbo].[RelatorioGeralKYCCVMPAD] (
    [data] varchar(MAX) NULL,
    [origem] varchar(MAX) NULL,
    [destino] varchar(MAX) NULL,
    [processo] varchar(MAX) NULL,
    [interessados] varchar(MAX) NULL,
    [requerente] varchar(MAX) NULL,
    [data_de_abertura] varchar(MAX) NULL,
    [fase] varchar(MAX) NULL,
    [assunto] varchar(MAX) NULL,
    [eletronico] bit NULL,
    [observacoes] varchar(MAX) NULL,
    [processo_eletrônico] varchar(MAX) NULL,
    [data_de_autuação] varchar(MAX) NULL,
    [tipo_do_processo] varchar(MAX) NULL,
    [IdRequisicao] bigint NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);