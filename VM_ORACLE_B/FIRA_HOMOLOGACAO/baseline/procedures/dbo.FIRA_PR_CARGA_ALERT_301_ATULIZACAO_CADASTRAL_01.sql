/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_301_ATULIZACAO_CADASTRAL_01]    Script Date: 25/02/2026 15:50:21 ******/

CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_ATULIZACAO_CADASTRAL_01] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS

/*************************************************************************************************
REGRA DO ALERTA:
Cliente que não teve atualização cadastral após 24 meses
da data de validade e que operou bvsp/bmf depois disso
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_ATULIZACAO_CADASTRAL_01_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_ATULIZACAO_CADASTRAL_01_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[TP_SITUAC] [nvarchar](255) NULL,
	[DT_VALIDADE] [datetime2](7) NULL,
	[DT_BVSP] [smalldatetime] NULL,
	[DS_NATUREZA_BVSP] [varchar](12) NULL,
	[DT_BMF] [datetime] NULL,
	[DS_NATUREZA_BMF] [varchar](12) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_ATULIZACAO_CADASTRAL_01_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_ATULIZACAO_CADASTRAL_01',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual
--declare @dt_ini_6m date = dateadd(month, datediff(month,0, dateadd(month,-7,@pregao)),0) -- primeiro dia do 6 mes anterior ao mes atual
--declare @dt_fim_6m date = @dt_ini -- 1 dia do mes atual

           
--CADASTRO
drop table if exists #TCLI_I
SELECT  A.CD_CLIENTE, TP_SITUAC,DT_VALIDADE          
INTO #TCLI_I    
FROM ST_DADOS_BASICOS_PF A     
WHERE DATEDIFF(MONTH,DT_VALIDADE,@PREGAO-@AUX) > 24          
GROUP BY  A.CD_CLIENTE, TP_SITUAC,DT_VALIDADE

	UNION ALL

SELECT  A.CD_CLIENTE, TP_SITUAC,DT_VALIDADE          
FROM ST_DADOS_BASICOS_PJ A     
WHERE DATEDIFF(MONTH,DT_VALIDADE,@PREGAO-@AUX) > 24          
GROUP BY  A.CD_CLIENTE, TP_SITUAC,DT_VALIDADE



--OPEROU      
drop table if exists #TCLI_OPE
SELECT 
		MAX(DT_BVSP)AS DT_BVSP,
		MAX(DT_BMF) AS DT_BMF,
		CD_CLIENTE, 
		CASE WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BMF, 
		CASE WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BVSP
	INTO #TCLI_OPE
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
		TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
		AND	DT_NEGOCIO = (SELECT MAX(DT_NEGOCIO) FROM ST_BMF_NEGOCIOS_NC XX    
						  WHERE XX.CD_CLIENTE =  ST_BMF_NEGOCIOS_NC.CD_CLIENTE
						  AND DT_NEGOCIO >= @dt_ini
						  AND DT_NEGOCIO < @dt_fim)            
		GROUP BY DT_NEGOCIO, CD_CLIENTE,CD_NATOPE  
		
	) XPTO 
	GROUP BY  CD_CLIENTE   


	--delete em caso de reprocessamento. 
	DELETE FROM ST_ALERT_ATULIZACAO_CADASTRAL_01 WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          

	--insert do alerta final   
	INSERT INTO ST_ALERT_ATULIZACAO_CADASTRAL_01 (DATA,CD_CLIENTE,TP_SITUAC,DT_VALIDADE,DT_BVSP,DS_NATUREZA_BVSP,DT_BMF,DS_NATUREZA_BMF) 
	SELECT DISTINCT 
		CAST(@PREGAO-@AUX AS DATE) AS DATA,          
		A.CD_CLIENTE,
		A.TP_SITUAC,
		A.DT_VALIDADE, 
		C.DT_BVSP, 
		DS_NATUREZA_BVSP,
		C.DT_BMF, 
		DS_NATUREZA_BMF
		
	FROM #TCLI_I A             
	LEFT OUTER JOIN #TCLI_OPE C 
	ON A.CD_CLIENTE = C.CD_CLIENTE         
	WHERE 
		DS_NATUREZA_BVSP  IS NOT NULL 
	OR 	DS_NATUREZA_BMF IS NOT NULL  
	
	ORDER BY 2,5   
          
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_ATULIZACAO_CADASTRAL_01', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_ALERT_ATULIZACAO_CADASTRAL_01]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_ATULIZACAO_CADASTRAL_01_PADRAO