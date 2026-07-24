CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_CARTEIRA_MEDIA_MENSAL] @PREGAOFIM SMALLDATETIME
AS

-- 1) cria tabela PADRAO baseada na estrutura atual da destino
DROP TABLE IF EXISTS [dbo].[ST_CARTEIRA_MEDIA_MENSAL_PADRAO];
CREATE TABLE [dbo].[ST_CARTEIRA_MEDIA_MENSAL_PADRAO] (
    [CD_ANOMES] INT NOT NULL,
    [CD_CLIENTE] INT NOT NULL,
    [MED_CARTEIRA] FLOAT NULL,
    [DT_FIRA] DATETIME NULL,
    CONSTRAINT [PK_ST_CARTEIRA_MEDIA_MENSAL_PADRAO] PRIMARY KEY CLUSTERED 
    (
        [CD_ANOMES] ASC,
        [CD_CLIENTE] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] ;

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_CARTEIRA_MEDIA_MENSAL_PADRAO',
  @schema_name='dbo', @base_table='ST_CARTEIRA_MEDIA_MENSAL',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

--DECLARE @PREGAOFIM DATETIME
--SET @PREGAOFIM = (CAST(GETDATE() AS date))

DECLARE @CD_ANOMES INT
SET @CD_ANOMES = (SELECT MAX(CD_ANOMES) FROM ST_PERIODO 
					WHERE DT_PERIODO = @PREGAOFIM);


DELETE FROM ST_CARTEIRA_MEDIA_MENSAL WHERE CD_ANOMES = @CD_ANOMES;

INSERT INTO ST_CARTEIRA_MEDIA_MENSAL (CD_ANOMES,CD_CLIENTE,MED_CARTEIRA)
	SELECT B.CD_ANOMES
		 , CD_CLIENTE
		 , ISNULL(AVG(CARTEIRA),0) AS MED_CARTEIRA 
      FROM ST_CARTEIRA_DIARIA A 
 LEFT JOIN ST_PERIODO B 
		ON A.DATA = B.DT_PERIODO
     WHERE B.CD_ANOMES = @CD_ANOMES

  GROUP BY CD_ANOMES
		  ,CD_CLIENTE

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_CARTEIRA_MEDIA_MENSAL', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_CARTEIRA_MEDIA_MENSAL]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_CARTEIRA_MEDIA_MENSAL_PADRAO