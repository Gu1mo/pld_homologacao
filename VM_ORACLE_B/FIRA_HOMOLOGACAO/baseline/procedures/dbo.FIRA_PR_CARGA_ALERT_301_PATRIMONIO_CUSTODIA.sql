CREATE   PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_PATRIMONIO_CUSTODIA] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS
 

/*************************************************************************************************
REGRA DO ALERTA:
Clientes que tiveram a carteira > patrimônio declarado absoluto no ultimo dia util do mes.
*************************************************************************************************/

/*************************************************************************************************
Observação:
verificar quais produtos temos na custodia para somar a carteira
ex.: Fundos, Renda Fixa, Ações, Derivativos(Ações Bmf), Saldo em Cc, Tesouro e etc..

Verificar de onde no sinacor o cliente está olhando o patrimonio
ex.: Bens declarados ? Renda mensal? Patrimonio Liq ? 
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_PATRIMONIO_CUSTODIA_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_PATRIMONIO_CUSTODIA_PADRAO](
	[DATA] [date] NULL,
	[DT_CUSTODIA] [datetime] NULL,
	[CD_CLIENTE] [int] NULL,
	[POSICAO_BOVESPA] [float] NULL,
	[POSICAO_BMF] [float] NULL,
	[POSICAO_CC] [float] NULL,
	[TESOURO] [float] NULL,
	[RENDA_FIXA] [float] NULL,
	[FUNDOS] [float] NULL,
	[CARTEIRA] [float] NULL,
	[PATRIMONIO] [float] NULL,
	[DS_NATUREZA_BVSP] [varchar](12) NOT NULL,
	[DS_NATUREZA_BMF] [varchar](12) NOT NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 



/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_PATRIMONIO_CUSTODIA_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_PATRIMONIO_CUSTODIA',
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


---busco o patrimonio do ultimo dia util do mes do alerta
DROP TABLE IF EXISTS #PATCUST
DECLARE @PERCENTUAL_ACRESCIMO NUMERIC(10,2) = (SELECT [CD_PARAMETRO] FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'PERCENTUAL_PATRIMONIO')
-- NULL = MANTÉM O PATRIMÔNIO ORIGINAL
-- 100  = ACRESCENTA 100%
-- 50   = ACRESCENTA 50%
-- 20   = ACRESCENTA 20%

SELECT P.CD_CLIENTE
,P.PATRIMONIO_ORIGINAL
,CAST(P.PATRIMONIO_ORIGINAL * (1 + ISNULL(@PERCENTUAL_ACRESCIMO, 0) / 100.0) AS NUMERIC(38,2)) AS PATRIMONIO
INTO #PATCUST
FROM (SELECT XX.CD_CLIENTE
,XX.TIPO
,CAST(CASE WHEN XX.TIPO = 'PF' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_SITU_PATRM) WHEN XX.TIPO = 'PJ' AND ISNULL(SUM(XX.VAL_BENS), 0) <= 0 THEN MAX(XX.VAL_PATRM_LIQ) ELSE SUM(XX.VAL_BENS) END AS NUMERIC(38,2)) AS PATRIMONIO_ORIGINAL
FROM ST_PATRIMONIO_LIQ XX
WHERE XX.DATA = (SELECT MAX(YY.DATA) FROM ST_PATRIMONIO_LIQ YY WHERE YY.DATA >= @DT_INI AND YY.DATA < @DT_FIM AND DATEPART(WEEKDAY, YY.DATA) NOT IN (1, 7))
GROUP BY XX.CD_CLIENTE
,XX.TIPO) P;
 
CREATE NONCLUSTERED INDEX T1         
ON [DBO].[#PATCUST] ([CD_CLIENTE]) 
INCLUDE ([PATRIMONIO])         
             
--verifico se o cliente operou bvsp/bmf
drop table if exists #TCLI_OPE_CUST
	SELECT 
		CD_CLIENTE, 
		MAX(DT_BVSP)AS DT_BVSP,
		MAX(DT_BMF) AS DT_BMF,
		CASE WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BMF) > 0 AND SUM(QT_VENDA_BMF) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BMF, 
		CASE WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) > 0 THEN 'COMPRA/VENDA'
			 WHEN SUM(QT_COMPRA_BVSP) > 0 AND SUM(QT_VENDA_BVSP) =0 THEN 'COMPRA' ELSE 'VENDA' END AS DS_NATUREZA_BVSP  
		
	INTO #TCLI_OPE_CUST
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
						  AND dt_negocio >= @dt_ini
						  AND dt_negocio < @dt_fim
						  )          
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
						  AND dt_negocio >= @dt_ini
						  AND dt_negocio < @dt_fim
						  )            
		GROUP BY DT_NEGOCIO, CD_CLIENTE,CD_NATOPE    
	) XPTO 
	GROUP BY CD_CLIENTE        


    --delete em caso de reprocessamento.    
	DELETE FROM ST_ALERT_PATRIMONIO_CUSTODIA WHERE DATA = CAST(@PREGAO-@AUX AS DATE)       
	
	----insert do alerta final     
	INSERT INTO ST_ALERT_PATRIMONIO_CUSTODIA (DATA,DT_CUSTODIA,CD_CLIENTE,POSICAO_BOVESPA,POSICAO_BMF,POSICAO_CC,TESOURO,RENDA_FIXA,FUNDOS,CARTEIRA,PATRIMONIO,DS_NATUREZA_BVSP,DS_NATUREZA_BMF)         
	SELECT
		CAST(@PREGAO-@AUX AS DATE) DATA,
		DT_CUSTODIA, 
		X.CD_CLIENTE,
		CAST(SUM(x.POSICAO_BOVESPA)AS FLOAT) AS POSICAO_BOVESPA,
		CAST(SUM(x.POSICAO_BMF)AS FLOAT) AS POSICAO_BMF,
		CAST(SUM(x.POSICAO_CC)AS FLOAT) AS POSICAO_CC,
		CAST(SUM(x.TESOURO)AS FLOAT) AS tesouro,
		CAST(SUM(x.RENDA_FIXA)AS FLOAT) AS renda_fixa,
		CAST(SUM(x.FUNDOS)AS FLOAT) AS FUNDOS,
		CAST(SUM(x.carteira)AS FLOAT) AS carteira,  
		CAST(ISNULL(#PATCUST.PATRIMONIO_ORIGINAL,0)AS FLOAT) AS PATRIMONIO, 
		ISNULL(DS_NATUREZA_BVSP,'NÃO') AS DS_NATUREZA_BVSP,        
		ISNULL(DS_NATUREZA_BMF,'NÃO') AS DS_NATUREZA_BMF  
		
	FROM  ST_PATRIMONIO_CUSTODIA x     
	LEFT OUTER JOIN #PATCUST 
		ON X.CD_CLIENTE = #PATCUST.CD_CLIENTE             
	LEFT OUTER JOIN #TCLI_OPE_CUST 
		ON X.CD_CLIENTE = #TCLI_OPE_CUST.CD_CLIENTE 
		 
 
	GROUP BY X.DT_CUSTODIA, X.CD_CLIENTE,ISNULL(#PATCUST.PATRIMONIO_ORIGINAL,0) ,ISNULL(DS_NATUREZA_BVSP,'NÃO'),ISNULL(DS_NATUREZA_BMF,'NÃO'), ISNULL(#PATCUST.PATRIMONIO,0)           
	HAVING ISNULL(CAST(SUM(x.carteira)AS FLOAT),0) > abs(ISNULL(#PATCUST.PATRIMONIO,0))            
             

/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_PATRIMONIO_CUSTODIA', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_PATRIMONIO_CUSTODIA
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_PATRIMONIO_CUSTODIA_PADRAO