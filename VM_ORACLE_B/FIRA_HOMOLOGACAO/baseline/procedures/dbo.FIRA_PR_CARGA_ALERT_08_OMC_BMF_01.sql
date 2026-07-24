/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_08_OMC_BMF_01]    Script Date: 25/02/2026 15:50:21 ******/

CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_08_OMC_BMF_01] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS

/*************************************************************************************************
REGRA DO ALERTA:
Identifica-se os clientes que realizaram operações de mesmo comitente.
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_OMC_BMF_01_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_OMC_BMF_01_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NULL,
	[NR_NEGOCIO] [numeric](12, 0) NULL,
	[QT_NEGOCIO_COMPRA] [float] NULL,
	[QT_NEGOCIO_VENDA] [float] NULL,
	[CD_NEGOCIO] [varchar](20) NULL,
	[HH_COMPRA] [varchar](5) NULL,
	[HH_VENDA] [varchar](5) NULL,
	[VL_TOTNEG_COMPRA] [float] NULL,
	[VL_TOTNEG_VENDA] [float] NULL,
	[VL_NEGOCIO_COMPRA] [float] NULL,
	[VL_NEGOCIO_VENDA] [float] NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_OMC_BMF_01_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_OMC_BMF_01',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual



DELETE FROM ST_ALERT_OMC_BMF_01 WHERE DATA = CAST(@PREGAO-@AUX AS DATE) 	
	
INSERT INTO ST_ALERT_OMC_BMF_01 
(
DATA,CD_CLIENTE,NR_NEGOCIO,QT_NEGOCIO_COMPRA,QT_NEGOCIO_VENDA,CD_NEGOCIO,HH_COMPRA
,HH_VENDA,VL_TOTNEG_COMPRA,VL_TOTNEG_VENDA,VL_NEGOCIO_COMPRA,VL_NEGOCIO_VENDA
)
SELECT DISTINCT 
CAST(@PREGAO-@AUX AS DATE)  DATA
, CD_CLIENTE_COMPRA CD_CLIENTE
,NR_NEGOCIO,QT_NEGOCIO_COMPRA
,QT_NEGOCIO_VENDA
,CD_NEGOCIO
,CONVERT(VARCHAR(5),HH_COMPRA) AS HH_COMPRA
,CONVERT(VARCHAR(5),HH_VENDA) AS HH_VENDA
,VL_TOTNEG_COMPRA
,VL_TOTNEG_VENDA
,VL_NEGOCIO_COMPRA
,VL_NEGOCIO_VENDA
FROM ST_DIRETAS_BMF	
WHERE 
	DT_NEGOCIO >= @dt_ini
AND DT_NEGOCIO < @dt_fim
AND CD_CLIENTE_COMPRA = CD_CLIENTE_VENDA	
GROUP BY 
CD_CLIENTE_COMPRA,NR_NEGOCIO,QT_NEGOCIO_COMPRA,
QT_NEGOCIO_VENDA,CD_NEGOCIO,HH_COMPRA,HH_VENDA,
VL_TOTNEG_COMPRA,VL_TOTNEG_VENDA,VL_NEGOCIO_COMPRA,VL_NEGOCIO_VENDA


/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_OMC_BMF_01', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_OMC_BMF_01
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_OMC_BMF_01_PADRAO