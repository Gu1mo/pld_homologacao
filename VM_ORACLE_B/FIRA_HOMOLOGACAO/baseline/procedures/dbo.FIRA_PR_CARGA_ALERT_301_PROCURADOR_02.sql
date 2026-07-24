CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_PROCURADOR_02] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS


/*************************************************************************************************
REGRA DO ALERTA:
Identifica os clientes que possuem emitente de ordens indicado junto à corretora.
*************************************************************************************************/


 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_PROCURADOR_02_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_PROCURADOR_02_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[DT_BVSP] [smalldatetime] NULL,
	[DT_BMF] [datetime] NULL,
	[DS_NATUREZA_BVSP] [varchar](12) NULL,
	[DS_NATUREZA_BMF] [varchar](12) NULL,
	[NM_CLIENTE] [varchar](400) NULL,
	[IN_PROCUR] [varchar](3) NULL,
	[NM_EMIT_ORDEM] [nvarchar](255) NULL,
	[CD_CPFCGC_EMIT] [varchar](20) NULL,
	[EMIT_PRINCIPAL] [varchar](3) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_PROCURADOR_02_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_PROCURADOR_02',
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
 
drop table if exists #TES
SELECT DISTINCT           
		A.CD_CLIENTE,
		A.CD_CPFCGC,
		A.NM_CLIENTE,
		A.IN_PROCUR,     
		A.NM_EMIT_ORDEM, 
		A.CD_CPFCGC_EMIT, 
		A.IN_PRINCIPAL AS EMIT_PRINCIPAL  
		
	INTO #TES         
	FROM ST_DADOS_BASICOS_PF A             
	WHERE 
		A.IN_PROCUR = 'S'        
	AND A.IN_PRINCIPAL ='S'           
	AND A.CD_CPFCGC <> A.CD_CPFCGC_EMIT

	UNION ALL
 
	SELECT DISTINCT           
		A.CD_CLIENTE,
		A.CD_CPFCGC,
		A.NM_CLIENTE,
		A.IN_PROCUR,     
		A.NM_EMIT_ORDEM, 
		A.CD_CPFCGC_EMIT, 
		A.IN_PRINCIPAL AS EMIT_PRINCIPAL   
	
	FROM ST_DADOS_BASICOS_PJ A              
	WHERE 
		A.IN_PROCUR = 'S'        
	AND A.IN_PRINCIPAL ='S'           
	AND A.CD_CPFCGC <> A.CD_CPFCGC_EMIT

 

             
--FINAL
	DELETE FROM ST_ALERT_PROCURADOR_02 WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          


	INSERT INTO ST_ALERT_PROCURADOR_02 (DATA,CD_CLIENTE,DT_BVSP,DT_BMF,DS_NATUREZA_BVSP,DS_NATUREZA_BMF,NM_CLIENTE,IN_PROCUR,NM_EMIT_ORDEM,CD_CPFCGC_EMIT,EMIT_PRINCIPAL)       
	SELECT 
		CAST(@PREGAO-@AUX AS DATE)DATA,
		XPTO.CD_CLIENTE,
		MAX(DT_BVSP)AS DT_BVSP,
		MAX(DT_BMF) AS DT_BMF,
		CASE WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BMF, 
		CASE WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BVSP,            
		Y.NM_CLIENTE,
		CASE WHEN Y.IN_PROCUR = 'S' THEN 'SIM' ELSE 'NÃO' END AS IN_PROCUR,             
		Y.NM_EMIT_ORDEM, 
		Y.CD_CPFCGC_EMIT,       
		CASE WHEN Y.EMIT_PRINCIPAL = 'S' THEN 'SIM' ELSE 'NÃO' END AS EMIT_PRINCIPAL           

	FROM (
		SELECT 
			DT_NEGOCIO AS DT_BVSP,
			NULL AS DT_BMF, 
			CD_CLIENTE, 
			CASE WHEN CD_NATOPE = 'C' THEN SUM(QT_MULTIPLICADOR) ELSE 0 END QT_COMPRA_BVSP,
			CASE WHEN CD_NATOPE = 'V' THEN SUM(QT_MULTIPLICADOR) ELSE 0 END QT_VENDA_BVSP,
			0 QT_COMPRA_BMF,
			0 QT_VENDA_BMF	
		FROM ST_CORRETAGEM_ORDEM   
		WHERE 
			DT_NEGOCIO = (SELECT MAX(DT_NEGOCIO) FROM ST_CORRETAGEM_ORDEM XX          
						  WHERE XX.CD_CLIENTE =  ST_CORRETAGEM_ORDEM.CD_CLIENTE      
						  AND DT_NEGOCIO >= @dt_ini
						  AND DT_NEGOCIO < @dt_fim)            
		GROUP BY DT_NEGOCIO, CD_CLIENTE,CD_NATOPE     

		UNION ALL

		SELECT  
			NULL AS DT_BVSP, 
			DT_NEGOCIO AS DT_BMF, 
			CD_CLIENTE, 
			0 QT_COMPRA_BVSP,
			0 QT_VENDA_BVSP,
			CASE WHEN CD_NATOPE = 'C' THEN SUM(QT_QTDDET) ELSE 0 END QT_COMPRA_BMF,
			CASE WHEN CD_NATOPE = 'V' THEN SUM(QT_QTDDET) ELSE 0 END QT_VENDA_BMF			
		FROM ST_BMF_NEGOCIOS_NC        
		WHERE 
		TP_NEGOCIO IN ('NORMAL',',DAY TRADE','DAYTRADE')
		AND	DT_NEGOCIO = (SELECT MAX(DT_NEGOCIO) FROM ST_BMF_NEGOCIOS_NC XX    
						  WHERE XX.CD_CLIENTE =  ST_BMF_NEGOCIOS_NC.CD_CLIENTE
						  AND DT_NEGOCIO >= @dt_ini
						  AND DT_NEGOCIO < @dt_fim)            
		GROUP BY DT_NEGOCIO, CD_CLIENTE,CD_NATOPE    

	) XPTO
	INNER JOIN #TES Y 
		ON XPTO.CD_CLIENTE = Y.CD_CLIENTE         
	GROUP BY  XPTO.CD_CLIENTE,Y.NM_CLIENTE,Y.IN_PROCUR,Y.NM_EMIT_ORDEM, Y.CD_CPFCGC_EMIT, Y.EMIT_PRINCIPAL           

	   
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_PROCURADOR_02', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_PROCURADOR_02
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_PROCURADOR_02_PADRAO