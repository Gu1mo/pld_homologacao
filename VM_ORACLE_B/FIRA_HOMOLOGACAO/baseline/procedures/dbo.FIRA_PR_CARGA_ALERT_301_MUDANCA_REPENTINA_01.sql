CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_MUDANCA_REPENTINA_01] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS

/*************************************************************************************************
REGRA DO ALERTA:
Alteração da modalidade operacional negociada pelo cliente no mês de análise ser 
diferente das modalidades operacionais negociadas nos últimos 6 meses e também precisa 
ter sido apontado no alerta de média (bvsp/bmf).
*************************************************************************************************/
/*********************************************************
Observações
- alterado em 13/03/2025 e 07/05/2025 por Heitor, coluna CD_TP_MERCADO agora trará mercado igual no relatório.
- alterado em 12/05/2025, para separar mercados hist. 6 meses por "|"
- alterado em 01/07/2025 por Heitor e Saulo, novo EXISTS com o alerta ST_ALERT_MUDANCA_REPENTINA_01 e BMF, só vai ser alertado se tiver caido na média bovespa ou na BMF.
*********************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_MUDANCA_REPENTINA_01_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_MUDANCA_REPENTINA_01_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[CD_TP_MERCADO] [nvarchar](255) NULL,
	[MERCADO_HIST_6M] [varchar](100) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_MUDANCA_REPENTINA_01_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_MUDANCA_REPENTINA_01',
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


--Mensal
drop table if exists #ONTEM
SELECT DISTINCT A.CD_CLIENTE, 
CASE      
WHEN TP_MERCADO = 'FRA' THEN 'VIS'   
WHEN TP_MERCADO = 'LEI' THEN 'VIS'
WHEN TP_MERCADO = 'VIS' THEN 'VIS'
WHEN TP_MERCADO = 'LNC' THEN 'VIS'
WHEN TP_MERCADO = 'ETF' THEN 'VIS'
WHEN TP_MERCADO = 'IER' THEN 'VIS'
WHEN TP_MERCADO = 'CET' THEN 'VIS'
WHEN TP_MERCADO = 'TER' THEN 'TER'
WHEN TP_MERCADO = 'OPV' THEN 'OPC'
WHEN TP_MERCADO = 'OPC' THEN 'OPC'  
WHEN TP_MERCADO = 'EOV' THEN 'OPC'  
WHEN TP_MERCADO = 'EOC' THEN 'OPC'
WHEN TP_MERCADO = 'OPD' THEN 'OPC'  
WHEN TP_MERCADO = 'OPF' THEN 'OPC'
ELSE TP_MERCADO END  CD_TP_MERCADO
INTO #ONTEM 
FROM ST_CORRETAGEM_ORDEM  A
WHERE
DT_NEGOCIO >= @dt_ini     
AND DT_NEGOCIO < @dt_fim     
            
UNION ALL        
             
SELECT DISTINCT CD_CLIENTE, 
CASE 
WHEN CD_MERCAD = 'DIS' THEN 'SPT'
WHEN CD_MERCAD = 'SPT' THEN 'SPT'
WHEN CD_MERCAD = 'FUT' THEN 'FUT'
WHEN CD_MERCAD = 'VFU' THEN 'FUT'
WHEN CD_MERCAD = 'BMF' THEN 'BMF'
WHEN CD_MERCAD = 'OPD' THEN 'OPC'  
WHEN CD_MERCAD = 'OPF' THEN 'OPC'
ELSE CD_MERCAD END CD_MERCAD
FROM ST_BMF_NEGOCIOS_NC
WHERE DT_NEGOCIO >= @dt_ini     
AND DT_NEGOCIO < @dt_fim   
AND TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE') 
             

--historico 6meses
drop table if exists #180DIAS      
SELECT DISTINCT A.CD_CLIENTE, 
CASE      
WHEN TP_MERCADO = 'FRA' THEN 'VIS'   
WHEN TP_MERCADO = 'LEI' THEN 'VIS'
WHEN TP_MERCADO = 'VIS' THEN 'VIS'
WHEN TP_MERCADO = 'LNC' THEN 'VIS'
WHEN TP_MERCADO = 'ETF' THEN 'VIS'
WHEN TP_MERCADO = 'IER' THEN 'VIS'
WHEN TP_MERCADO = 'CET' THEN 'VIS'
WHEN TP_MERCADO = 'TER' THEN 'TER'
WHEN TP_MERCADO = 'OPV' THEN 'OPC'
WHEN TP_MERCADO = 'OPC' THEN 'OPC'  
WHEN TP_MERCADO = 'EOV' THEN 'OPC'  
WHEN TP_MERCADO = 'EOC' THEN 'OPC'
WHEN TP_MERCADO = 'OPD' THEN 'OPC'  
WHEN TP_MERCADO = 'OPF' THEN 'OPC'
ELSE TP_MERCADO END CD_TP_MERCADO        
INTO #180DIAS
FROM ST_CORRETAGEM_ORDEM  A 

WHERE 
	DT_NEGOCIO >= @dt_ini_6m     
AND DT_NEGOCIO <  @dt_fim_6m       
             
UNION ALL        
             
SELECT DISTINCT CD_CLIENTE, 
CASE 
WHEN CD_MERCAD = 'DIS' THEN 'SPT'
WHEN CD_MERCAD = 'SPT' THEN 'SPT'
WHEN CD_MERCAD = 'FUT' THEN 'FUT'
WHEN CD_MERCAD = 'VFU' THEN 'FUT'
WHEN CD_MERCAD = 'BMF' THEN 'BMF'
WHEN CD_MERCAD = 'OPD' THEN 'OPC'  
WHEN CD_MERCAD = 'OPF' THEN 'OPC'
ELSE CD_MERCAD END CD_MERCAD
FROM ST_BMF_NEGOCIOS_NC
WHERE DT_NEGOCIO >= @dt_ini_6m
AND DT_NEGOCIO < @dt_fim_6m    
AND TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE') 
 
CREATE NONCLUSTERED INDEX [t180]
ON [dbo].[#180DIAS] ([CD_CLIENTE],[CD_TP_MERCADO])
             


--delete em caso de reprocessamento.
DELETE FROM ST_ALERT_MUDANCA_REPENTINA_01 WHERE DATA = CAST(@PREGAO-@AUX AS DATE)          

----insert do alerta final           
INSERT INTO ST_ALERT_MUDANCA_REPENTINA_01 (DATA,CD_CLIENTE,CD_TP_MERCADO,MERCADO_HIST_6M)
SELECT DISTINCT 
    CAST(@PREGAO-@AUX AS DATE) AS DATA,
    A.CD_CLIENTE,
	COALESCE( (SELECT CAST(o.CD_TP_MERCADO AS VARCHAR(MAX)) + ' | ' [text()] 
			FROM #ONTEM AS O 
			WHERE O.CD_CLIENTE = A.CD_CLIENTE --AND O.CD_ANOMES = A.CD_ANOMES 
			ORDER BY CAST(o.CD_TP_MERCADO AS VARCHAR(MAX)) 
			FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)'), '') AS CD_TP_MERCADO,
    STUFF((SELECT ' | ' + s.CD_TP_MERCADO
           FROM #180DIAS s
           WHERE s.CD_CLIENTE = A.cd_cliente
           FOR XML PATH(''), TYPE
          ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS MERCADO_HIST_6M
FROM #ONTEM A
WHERE NOT EXISTS (SELECT CD_CLIENTE 
                  FROM #180DIAS D     
                  WHERE D.CD_CLIENTE = A.CD_CLIENTE  
                  AND D.CD_TP_MERCADO = A.CD_TP_MERCADO) 

AND EXISTS (SELECT CD_CLIENTE 
            FROM #180DIAS D    
            WHERE D.CD_CLIENTE = A.CD_CLIENTE)

AND (
        EXISTS (
            SELECT 1 
            FROM ST_ALERT_MEDIA_BOVESPA_01 M
            WHERE M.CD_CLIENTE = A.CD_CLIENTE
              AND M.DATA = CAST(@PREGAO - @AUX AS DATE)
        )
        OR
        EXISTS (
            SELECT 1 
            FROM ST_ALERT_MEDIA_BMF_01 B
            WHERE B.CD_CLIENTE = A.CD_CLIENTE
              AND B.DATA = CAST(@PREGAO - @AUX AS DATE)
        )
    );
 
										  
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_MUDANCA_REPENTINA_01', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_MUDANCA_REPENTINA_01
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_MUDANCA_REPENTINA_01_PADRAO