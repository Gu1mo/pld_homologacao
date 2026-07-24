CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_CARTEIRA_DIARIA]  @PREGAO DATETIME, @PREGAOFIM DATETIME
AS 


DROP TABLE IF EXISTS [dbo].[ST_CARTEIRA_DIARIA_PADRAO];
CREATE TABLE [dbo].[ST_CARTEIRA_DIARIA_PADRAO] (
    [DATA] SMALLDATETIME NOT NULL,
    [CD_CLIENTE] INT NOT NULL,
    [CARTEIRA] FLOAT NULL,
    [DT_FIRA] DATETIME NULL,
    CONSTRAINT [PK_ST_CARTEIRA_DIARIA_PADRAO] PRIMARY KEY CLUSTERED 
    (
        [DATA] ASC,
        [CD_CLIENTE] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] ;

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_CARTEIRA_DIARIA_PADRAO',
  @schema_name='dbo', @base_table='ST_CARTEIRA_DIARIA',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;


--DECLARE @PREGAO DATETIME, @PREGAOFIM DATETIME
--SET @PREGAO ='20260201'
--SET @PREGAOFIM ='20260214'

-- ~ 20 minutos por mês (nuinvest)	
WHILE @PREGAO < @PREGAOFIM 	
BEGIN	

DELETE FROM ST_CARTEIRA_DIARIA WHERE [DATA] = @PREGAO;

INSERT INTO ST_CARTEIRA_DIARIA ([DATA],CD_CLIENTE,CARTEIRA)
   SELECT DT_CUSTODIA
		, CD_CLIENTE
		, SUM(CARTEIRA) CARTEIRA
	FROM ST_PATRIMONIO_CUSTODIA B (NOLOCK) 
   WHERE DT_CUSTODIA = @PREGAO
GROUP BY DT_CUSTODIA
	   , CD_CLIENTE;

  SET @PREGAO = DATEADD(DAY,1,@PREGAO)

END;
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_CARTEIRA_DIARIA', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_CARTEIRA_DIARIA]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_CARTEIRA_DIARIA_PADRAO