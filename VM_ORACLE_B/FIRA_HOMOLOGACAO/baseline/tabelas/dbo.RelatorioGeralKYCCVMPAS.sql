CREATE TABLE [dbo].[RelatorioGeralKYCCVMPAS] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [IdRequisicao] int NULL,
    [movimentacoes] varchar(5000) NULL,
    [fase_atual] varchar(150) NULL,
    [subfase_atual] varchar(150) NULL,
    [data_ultima_mudanca_fase_subfase] date NULL,
    [local_atual] varchar(100) NULL,
    [data_ultima_movimentacao_local] date NULL,
    [numero] varchar(150) NULL,
    [assunto_objeto] varchar(2000) NULL,
    [data_abertura] date NULL,
    [encarregado_instrucao] varchar(50) NULL,
    [acusados] varchar(MAX) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_RelatorioGeralKYCCVMPAS] PRIMARY KEY ([Id])
);