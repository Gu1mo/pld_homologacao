CREATE TABLE [dbo].[RelatorioGeralKYCRFBPF] (
    [id] int IDENTITY(1,1) NOT NULL,
    [nome] nvarchar(MAX) NULL,
    [cpf] nvarchar(MAX) NULL,
    [data_inscricao] nvarchar(MAX) NULL,
    [data_nascimento] nvarchar(MAX) NULL,
    [genero] nvarchar(MAX) NULL,
    [situacao_cadastral] nvarchar(MAX) NULL,
    [uf] nvarchar(MAX) NULL,
    [ano_obito] nvarchar(MAX) NULL,
    [comprovante] nvarchar(MAX) NULL,
    [digito_verificador] nvarchar(MAX) NULL,
    [id_requisicao] int NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_RelatorioGeralKYCRFBPF] PRIMARY KEY ([id])
);