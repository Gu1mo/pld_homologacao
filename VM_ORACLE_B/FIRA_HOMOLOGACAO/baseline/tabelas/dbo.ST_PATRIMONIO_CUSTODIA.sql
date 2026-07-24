CREATE TABLE [dbo].[ST_PATRIMONIO_CUSTODIA] (
    [DT_CUSTODIA] datetime NULL,
    [CD_CLIENTE] int NOT NULL,
    [NM_CLIENTE] nvarchar(160) NULL,
    [CD_CPFCGC] varchar(20) NULL,
    [DS_ATIV] varchar(160) NULL,
    [DT_ATUALIZ] varchar(30) NULL,
    [PATRIMONIO] float NULL,
    [POSICAO_CC] float NULL,
    [POSICAO_BOVESPA] float NULL,
    [POSICAO_BMF] float NULL,
    [TESOURO] float NULL,
    [RENDA_FIXA] float NULL,
    [FUNDOS] float NULL,
    [CARTEIRA] float NULL,
    [INCOMPATIVEL] varchar(3) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);