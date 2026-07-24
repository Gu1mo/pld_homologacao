CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_PATRIMONIO_TRANF_CUST] @PREGAO SMALLDATETIME, @AUX INT  
--WITH ENCRYPTION   
AS  

/*************************************************************************************************
REGRA DO ALERTA:
Soma de todos os valores de transferidos custódia (total mês) maior que o patrimônio declarado absoluto
no ultimo dia util do mes.
*************************************************************************************************/


 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_PATRIMONIO_TRANF_CUST_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_PATRIMONIO_TRANF_CUST_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NULL,
	[TOTAL_MES] [numeric](38, 2) NULL,
	[PATRIMONIO] [numeric](38, 2) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_PATRIMONIO_TRANF_CUST_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_PATRIMONIO_TRANF_CUST',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual
declare @dt_ini_6m date = dateadd(month, datediff(month,0, dateadd(month,-7,@pregao)),0) -- primeiro dia do 6 mes anterior ao mes atual
declare @dt_fim_6m date = @dt_ini -- 1 dia do mes atual
DECLARE @DT_REF DATE = DATEADD(DAY, - @AUX, @PREGAO);

drop table if exists #PATRIMONIO_TRANSF
DECLARE @PERCENTUAL_ACRESCIMO NUMERIC(10,2) = (SELECT [CD_PARAMETRO] FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'PERCENTUAL_PATRIMONIO')
-- NULL = mantém o patrimônio original
-- 100  = acrescenta 100%
-- 50   = acrescenta 50%
-- 20   = acrescenta 20%

SELECT P.CD_CLIENTE
,P.PATRIMONIO_ORIGINAL
,CAST(P.PATRIMONIO_ORIGINAL * (1 + ISNULL(@PERCENTUAL_ACRESCIMO, 0) / 100.0) AS NUMERIC(38,2)) AS PATRIMONIO
INTO #PATRIMONIO_TRANSF
FROM (SELECT XX.CD_CLIENTE
,XX.TIPO
,CAST(CASE WHEN XX.TIPO = 'PF' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_SITU_PATRM) WHEN XX.TIPO = 'PJ' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_PATRM_LIQ) ELSE SUM(XX.VAL_BENS) END AS NUMERIC(38,2)) AS PATRIMONIO_ORIGINAL
FROM ST_PATRIMONIO_LIQ XX
WHERE XX.DATA = (SELECT MAX(YY.DATA) FROM ST_PATRIMONIO_LIQ YY WHERE YY.DATA >= @DT_INI AND YY.DATA < @DT_FIM AND DATEPART(WEEKDAY, YY.DATA) NOT IN (1, 7))
GROUP BY XX.CD_CLIENTE
,XX.TIPO) P;
    
CREATE NONCLUSTERED INDEX T1 ON [DBO].[#PATRIMONIO_TRANSF] ([CD_CLIENTE]) INCLUDE ([PATRIMONIO])     
  
--volume do papel das cotações historicas B3
drop table if exists #TPAPEL1
 SELECT   
  DT_PERIODO,   
  CODNEG AS CD_PAPEL,  
  CAST(MAX(PREMAX)AS FLOAT)/FATCOT AS VL_NEGOCIO   
 INTO #TPAPEL1  
 FROM ST_ATIVO_BOVESPA  
 WHERE   
 DT_PERIODO >= @dt_ini 
 AND DT_PERIODO < @dt_fim
 GROUP BY DT_PERIODO,CODNEG,FATCOT
   
  
 --delete em caso de reprocessamento. 
 DELETE FROM ST_ALERT_PATRIMONIO_TRANF_CUST WHERE DATA = CAST(@PREGAO-@AUX AS DATE)            
      
------insert do alerta final
 INSERT INTO ST_ALERT_PATRIMONIO_TRANF_CUST (DATA,CD_CLIENTE,TOTAL_MES,PATRIMONIO)
 SELECT   
   CAST(@PREGAO-@AUX AS DATE) AS DATA  
  ,X.CD_CLIENTE  
  ,SUM(TRANSFERENCIA) AS TRANSFERENCIA  
  ,ISNULL(TT.PATRIMONIO_ORIGINAL,0) AS PATRIMONIO   
 FROM(  
	  SELECT DATA_MVTO,COD_CLI CD_CLIENTE, S.COD_NEG,  
	  PP.VL_NEGOCIO  * QTDE_MVTO TRANSFERENCIA  
	  FROM ST_TRANSFERENCIA_CUST S   
	  LEFT OUTER JOIN #TPAPEL1 PP ON S.COD_NEG = PP.CD_PAPEL AND S.DATA_MVTO = PP.DT_PERIODO  
	  WHERE  
	  DATA_MVTO >= @dt_ini 
	  and DATA_MVTO < @dt_fim
	  AND NAT_OPE  = 'C'  
	  AND TIPO_MVTO = 'LC03'  
	  AND COD_MVTO =  6	     
	  AND COD_NEG > '0'  
	  AND COD_USUA_CONP NOT IN (select MAX(cd_parametro) from ST_CLIENTE_PARAMETROS where DS_PARAMETRO = 'CD_CONTRAPARTE')
	 ) X    
 LEFT OUTER JOIN  #PATRIMONIO_TRANSF TT ON X.CD_CLIENTE = TT.CD_CLIENTE   

 GROUP BY X.CD_CLIENTE ,ISNULL(TT.PATRIMONIO_ORIGINAL,0),ISNULL(TT.PATRIMONIO,0)
 HAVING SUM(TRANSFERENCIA) > abs(ISNULL(TT.PATRIMONIO,0)) ---> REGRA DO ALERTA  
  
  
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_PATRIMONIO_TRANF_CUST', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_PATRIMONIO_TRANF_CUST
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_PATRIMONIO_TRANF_CUST_PADRAO