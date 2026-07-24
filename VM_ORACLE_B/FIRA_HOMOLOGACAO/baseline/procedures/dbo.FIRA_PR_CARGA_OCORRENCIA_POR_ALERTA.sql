CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_OCORRENCIA_POR_ALERTA]
AS
 --delete from incident 
 --DBCC CHECKIDENT ('incident', RESEED, 0);
  /*
 Atualizações
 05/09/2024  - 16h11 - Author: Guimo
 Retirada dos alertas de daytrade e swingtrade.

  12/09/2024  - 16h15 - Author: Guimo
  Alerta de OMC BMF  estava duplicando a linha de exemplo: Mês de Referência MARÇO/2024

  20/05/25 add alerta oscilação: heitor
  23/05/25 add insert REFERENCIA: heitor/guimo
  02/07/25 add novo bloco do @reference_id
 */
declare @pregao smalldatetime ;
declare @relatoAbertura nvarchar(max)
DECLARE @cd_cliente INT 

declare @dt_alerta smalldatetime
DECLARE @MES INT
DECLARE @ANO INT	
DECLARE @MES_TEXT VARCHAR(10)
DECLARE @DIA_UTIL INT

SET @PREGAO = CAST(getdate() AS DATE) --getdate() '2024-03-06'
set @dt_alerta = EOMONTH ( @PREGAO, -1 ) 
SET @ANO = YEAR(@dt_alerta )
SET @MES = MONTH(@dt_alerta)

	 IF @MES = '01' BEGIN SET @MES_TEXT = 'JANEIRO' END
ELSE IF @MES = '02' BEGIN SET @MES_TEXT = 'FEVEREIRO' END
ELSE IF @MES = '03' BEGIN SET @MES_TEXT = 'MARÇO' END
ELSE IF @MES = '04' BEGIN SET @MES_TEXT = 'ABRIL' END
ELSE IF @MES = '05' BEGIN SET @MES_TEXT = 'MAIO' END
ELSE IF @MES = '06' BEGIN SET @MES_TEXT = 'JUNHO' END
ELSE IF @MES = '07' BEGIN SET @MES_TEXT = 'JULHO' END
ELSE IF @MES = '08' BEGIN SET @MES_TEXT = 'AGOSTO' END
ELSE IF @MES = '09' BEGIN SET @MES_TEXT = 'SETEMBRO' END
ELSE IF @MES = '10' BEGIN SET @MES_TEXT = 'OUTUBRO' END
ELSE IF @MES = '11' BEGIN SET @MES_TEXT = 'NOVEMBRO' END
ELSE IF @MES = '12' BEGIN SET @MES_TEXT = 'DEZEMBRO' END

/** PEGA O QUARTO DIA UTIL DO MES **/
SET @DIA_UTIL = DBO.DIA_UTIL(@PREGAO)--(SELECT count(1) FROM ST_PERIODO WHERE CD_ANO  = YEAR(@PREGAO) AND CD_MES  = MONTH(@PREGAO) AND CD_DIA <= DAY(@PREGAO) AND DS_DIASEMANA NOT IN ('SABADO','DOMINGO'));

IF @DIA_UTIL = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO  = 'DIA_UTIL')
BEGIN
-----------------------------------
DROP TABLE IF EXISTS #T1;
CREATE TABLE #T1 (CD_CLIENTE NUMERIC(8,0),ALERTAS VARCHAR(150), DESCRIPTION VARCHAR(MAX))
	
	declare @default_summary varchar(20) 
	declare @area_id int
	declare @source_id int
	declare @group_id int
	declare @reporter_id int
	declare @assignee_id int
	declare @state_id int
	declare @sla_type varchar(100)
	declare @sla_time varchar(100)
	declare @date_start smalldatetime
	declare @alert_name varchar(max) 
	declare @client_name varchar(max)
	declare @client_document varchar(max)
	declare @priority varchar(max)
	declare @priority_id int
	declare @description varchar(max)
	declare @client_code varchar(max)
	declare @subgroup_id int
	declare @reference_id int
	
	----comentar para reprocessar
	--insert into REFERENCIA (REF_PERIODO, REF_ANO, VISIVEL, SOMENTELEITURA)
	--select @MES, @ANO, null, null
	--where not exists (
	--	select * from REFERENCIA where REF_PERIODO = @MES and REF_ANO = @ANO
	--)

--	set @reference_id = (select max(id) from referencia a 
--inner join st_periodo b on a.REF_PERIODO = b.DS_MES 
--and a.REF_ANO = b.CD_ANO
--where b.DT_PERIODO = @pregao)
	
		set @reference_id = (select max(id) from referencia a 
							inner join VDASH_ALERTAS b on a.REF_PERIODO  =
							case when  month(b.dt_periodo) = '01' then 'JANEIRO' 
								 when  month(b.dt_periodo) = '02' then 'FEVEREIRO' 
								 when  month(b.dt_periodo) = '03' then 'MARÇO' 
								 when  month(b.dt_periodo) = '04' then 'ABRIL' 
								 when  month(b.dt_periodo) = '05' then 'MAIO' 
								 when  month(b.dt_periodo) = '06' then 'JUNHO' 
								 when  month(b.dt_periodo) = '07' then 'JULHO' 
								 when  month(b.dt_periodo) = '08' then 'AGOSTO' 
								 when  month(b.dt_periodo) = '09' then 'SETEMBRO' 
								 when  month(b.dt_periodo) = '10' then 'OUTUBRO' 
								 when  month(b.dt_periodo) = '11' then 'NOVEMBRO' 
								 when  month(b.dt_periodo) = '12' then 'DEZEMBRO' end
							and a.REF_ANO = year(b.dt_periodo)
							where b.DT_PERIODO = @dt_alerta
							)

	set @default_summary = 'Cliente Alertado'
	set @area_id = coalesce(
		(select id from incident_area where name = 'Compliance'),
		(select top 1 id from incident_area)
	)

	set @source_id = coalesce(
		(select id from incident_source where name = 'Automática'),
		(select top 1 id from incident_source)
	)

	set @group_id = coalesce(
		(select id from incident_group where name = 'Alerta FIRA'),
		(select top 1 id from incident_group)
	)

	set @reporter_id = coalesce(
		(select id from usuarioportal where usuario = 'admin'),
		(select top 1 id from usuarioportal)
	)

	set @assignee_id = coalesce(
		(select id from usuarioportal where usuario = 'admin'),
		(select top 1 id from usuarioportal)
	)

	set @state_id = coalesce(
		(select id from incident_state where [name] = 'Aberto'),
		(select top 1 id from incident_state)
	)

	set @sla_type = 'Tempo de Solução'
	set @sla_time = '45D'

	set @date_start = @PREGAO



-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

DECLARE cursor_por_alerta CURSOR FOR
	SELECT 
  DISTINCT CD_CLIENTE
	  FROM VDASH_ALERTAS (NOLOCK)
	 WHERE DT_PERIODO = @dt_alerta

OPEN cursor_por_alerta;

FETCH NEXT FROM cursor_por_alerta INTO @cd_cliente;

WHILE @@FETCH_STATUS = 0
BEGIN 


-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH ATULIZACAO_CADASTRAL_01 AS (
    SELECT 
        CONCAT('Situação cadastral: ', TP_SITUAC
		, '<br>'
		, 'Data de validade: ', convert(varchar,DT_VALIDADE,103)
		, '<br>'
		, 'Data de operação Bovespa: ', convert(varchar,DT_BVSP,103)
		, '<br>'
		, 'Natureza Bovespa: ',DS_NATUREZA_BVSP 
		, '<br>'
		, 'Data da operação BMF: ', DT_BMF
		, '<br>'
		, 'Natureza BMF:', DS_NATUREZA_BMF
		, '<br>'
        ) +'<br>' AS HTML
    FROM ST_ALERT_ATULIZACAO_CADASTRAL_01
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE			  AS [CD_CLIENTE]
	 ,'Atualização Cadastral' AS [ALERTAS]
	 , concat('Atualização Cadastral'
		 , '<br>') 
		 + STUFF(
		(
		    SELECT '' + a.HTML 
		    FROM ATULIZACAO_CADASTRAL_01 a
		    FOR XML PATH(''), TYPE
		).value('.', 'NVARCHAR(MAX)'), 1, 0, '')  AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH BMF_AML AS (
    SELECT 
        CONCAT(
            '<br>Código do cliente ponta:', CAST(CD_CLIENTE_PONTA AS VARCHAR)
			, '<br>',
            'Resultado: ', CAST(CAST(VOLUME AS NUMERIC(17,2)) AS VARCHAR)
			, '<br>',
            'Média: ', CAST(CAST(MEDIA AS NUMERIC(17,2)) AS VARCHAR)
			, '<br>',
            'Desvio:', CAST(CAST(DESVIO AS NUMERIC(17,2)) AS VARCHAR)
			, '<br>'
        )+'<br>' AS HTML
    FROM ST_ALERT_BMF_AML
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE AS [CD_CLIENTE]
	 ,'Aml Bmf'    AS [ALERTAS]
		 , concat('Aml Bmf'
		 , '<br>') 
			 + STUFF(
		 (
		     SELECT '' + a.HTML 
		     FROM BMF_AML a
		     FOR XML PATH(''), TYPE
		 ).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH AML_BOVESPA AS (
    SELECT 
        CONCAT(
            '<br>Código do cliente ponta: ', CAST(CD_CLIENTE_PONTA AS VARCHAR)
			, '<br>',
            'Resultado: ', CAST(CAST(VOLUME AS NUMERIC(17,2)) AS VARCHAR)
			, '<br>',
            'Média:', CAST(CAST(MEDIA AS NUMERIC(17,2)) AS VARCHAR)
			, '<br>',
            'Desvio:', CAST(CAST(DESVIO AS NUMERIC(17,2)) AS VARCHAR)
			, '<br><br>'
        )+'<br>' AS HTML
    FROM ST_ALERT_BOVESPA_AML
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE		   AS CD_CLIENTE
	 ,'Aml Bvsp'		   AS [ALERTAS]
	 ,concat('Aml Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM AML_BOVESPA a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH CHURNING_BOVESPA_02 AS (
    SELECT 
		CONCAT(' Com um cost equity de '
			   ,format(COST_EQUITY_RATIO,'C','pt-br')
			   ,' sendo acima de 21%, e um turnover ratio de '
			   ,format(TURNOVER_RATIO,'C','pt-br'),' sendo acima de 2%')+'<br>'
      
         AS HTML
    FROM ST_ALERT_CHURNING_BOVESPA_02
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE		   AS CD_CLIENTE
	 ,'Churning'		   AS [ALERTAS]
	 ,concat('Churning'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM CHURNING_BOVESPA_02 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- ;WITH DAYTRADE_BMF_01 AS (
--    SELECT 
--		CONCAT(' Com um volume de R$',format(VL_FINANC,'C','pt-br'),' maior que a média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e desvio de R$',
--				format(DESVIO,'C','pt-br')) +'<br>'
 
--         AS HTML
--    FROM ST_ALERT_DAYTRADE_BMF_01
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE		   AS CD_CLIENTE
--	 ,'DAYTRADE BMF'		   AS [ALERTAS]
--	 ,concat('DAYTRADE BMF'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '' + a.HTML 
--			    FROM DAYTRADE_BMF_01 a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- ;WITH DAYTRADE_BOVESPA_01 AS (
--    SELECT 
--		CONCAT(' Com um volume de R$',format(VL_FINANC,'C','pt-br'),' maior que a média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e desvio de R$',
--				format(DESVIO,'C','pt-br')) +'<br>'
 
--         AS HTML
--    FROM ST_ALERT_DAYTRADE_BOVESPA_01
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE		   AS CD_CLIENTE
--	 ,'DAYTRADE BVSP'	   AS [ALERTAS]
--	 ,concat('DAYTRADE BVSP'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '' + a.HTML 
--			    FROM DAYTRADE_BOVESPA_01 a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]  
		
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH INSIDER_TRADING_02 AS (
    SELECT 
		CONCAT(' Após a publicação do fato relevante: ',FATO_RELEVANTE,' cliente obteve o resultado de  ',format(RESULTADO,'C','pt-br'), '<br>') +'<br>'
 
         AS HTML
    FROM ST_ALERT_INSIDER_TRADING_02
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Insider Trading'	   AS [ALERTAS]
	 ,concat('Insider Trading'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM INSIDER_TRADING_02 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- ;WITH LAYRERING_02 AS (
--    SELECT 
--		CONCAT(' Com valor anterior ',format(VALOR_ANTES,'C','pt-br'),' e uma quantidade cancelada ',
--				format(QT_CANCOF,'#,0','pt-br'),' e tve um valor posterior ',format(VALOR_POS,'C','pt-br'))+'<br>'
--         AS HTML
--    FROM ST_ALERT_LAYRERING_02
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE				   AS CD_CLIENTE
--	 ,'Layering'	   AS [ALERTAS]
--	 ,concat('Layering'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '' + a.HTML 
--			    FROM LAYRERING_02 a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

 ;WITH LISTA_ATENCAO AS (
    SELECT 
		CONCAT(' ',replace(RSLT_CONS,',','<br><br>'))+'<br>'
         AS HTML
    FROM ST_ALERT_LISTA_ATENCAO
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Lista Atenção'	   AS [ALERTAS]
	 ,concat('Lista Atenção</b>'
			 ,' <br> Apontado em: <br>') 
			 + STUFF(
			(
			    SELECT ' ' + a.HTML 
			    FROM LISTA_ATENCAO a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH MEDIA_BMF_01 AS (
    SELECT 
		CONCAT(' Com quantidade de contratos ',format(VOLUME,'C','pt-br'),' maior que a média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e desvio de R$',
				format(DESVIO,'C','pt-br'))+'<br>' 
				AS HTML
    FROM ST_ALERT_MEDIA_BMF_01
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Média Oper. Bmf'	   AS [ALERTAS]
	 ,concat('Média Oper. Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MEDIA_BMF_01 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH MEDIA_BOVESPA_01 AS (
    SELECT 
		CONCAT(' Com volume de R$',format(VOLUME,'C','pt-br'),' maior que a média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e desvio de R$',
				format(DESVIO,'C','pt-br')) +'<br>'
				AS HTML
    FROM ST_ALERT_MEDIA_BOVESPA_01
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Média Oper. Bvsp'	   AS [ALERTAS]
	 ,concat('Média Oper. Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MEDIA_BOVESPA_01 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH MONEYPASS_BMF AS (
    SELECT  CONCAT( 'O cliente apresentou, em operações com a contraparte ' 
,FORMAT(CD_CONTRAPARTE, 'N0', 'pt-BR')
,' nos ativos: ',COALESCE(PAPEIS, N'(não informado)')
,' um resultado de ',format(RESULTADO,'C','pt-br')
,' superior à média dos últimos seis meses ',format(RESULTADO_MEDIA_6M,'C','pt-br')
,', acrescida de ',format(RESULTADO_DESVIO_6M,'C','pt-br')
,' desvios padrão. Além disso, registrou concentração de ',format(CONCENTRACAO,'N2','pt-br')
,'% acima da média histórica de ',format(CONCENTRACAO_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(CONCENTRACAO_DESVIO_6M,'N2','pt-br')
,'%.
O índice de acerto foi de ',format(IND_ACERTO,'N2','pt-br')
,'% e o índice de erro, de ',format(IND_ERRO,'N2','pt-br')
,'%.
Por fim, apresentou intencionalidade de ',format(INTENCIONALIDADE,'N2','pt-br')
,'% comparada à média dos últimos seis meses de ',format(INTENCIONALIDADE_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(INTENCIONALIDADE_DESVIO_6M,'N2','pt-br')
,'%.')+'<br>' AS HTML
    FROM ST_ALERT_MONEYPASS_BMF_02
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Money Pass Bmf'	   AS [ALERTAS]
	 ,concat('Money Pass Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MONEYPASS_BMF a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
;WITH MONEYPASS_BOVESPA AS (
    SELECT  CONCAT( 'O cliente apresentou, em operações com a contraparte ' 
,FORMAT(CD_CONTRAPARTE, 'N0', 'pt-BR')
,' nos ativos: ',COALESCE(PAPEIS, N'(não informado)')
,' um resultado de ',format(RESULTADO,'C','pt-br')
,' superior à média dos últimos seis meses ',format(RESULTADO_MEDIA_6M,'C','pt-br')
,', acrescida de ',format(RESULTADO_DESVIO_6M,'C','pt-br')
,' desvios padrão. Além disso, registrou concentração de ',format(CONCENTRACAO,'N2','pt-br')
,'% acima da média histórica de ',format(CONCENTRACAO_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(CONCENTRACAO_DESVIO_6M,'N2','pt-br')
,'%.
O índice de acerto foi de ',format(IND_ACERTO,'N2','pt-br')
,'% e o índice de erro, de ',format(IND_ERRO,'N2','pt-br')
,'%.
Por fim, apresentou intencionalidade de ',format(INTENCIONALIDADE,'N2','pt-br')
,'% comparada à média dos últimos seis meses de ',format(INTENCIONALIDADE_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(INTENCIONALIDADE_DESVIO_6M,'N2','pt-br')
,'%.')+'<br>' AS HTML
    FROM ST_ALERT_MONEYPASS_02
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Money Pass Bvsp'   AS [ALERTAS]
	 ,concat('Money Pass Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MONEYPASS_BOVESPA a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH MUDANCA_REPENTINA_01 AS (
    SELECT  CONCAT(' Com outro tipo de modalidade nos ultimos 6 M :',CD_TP_MERCADO) +'<br>'
				 
				AS HTML
    FROM ST_ALERT_MUDANCA_REPENTINA_01
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Mudança Repentina'	   AS [ALERTAS]
	 ,concat('Mudança Repentina'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MUDANCA_REPENTINA_01 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH OMC_01 AS (
    SELECT  DISTINCT CONCAT(' Mês de Referência ',(select ds_mes +'/'+cast(cd_ano as varchar) referencia from ST_PERIODO where dt_periodo = data))+'<br>' 
				
				 
				AS HTML
    FROM ST_ALERT_OMC_01 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Omc Bvsp'	   AS [ALERTAS]
	 ,concat('Omc Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM OMC_01 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH OMC_BMF_01  AS (
    SELECT  DISTINCT CONCAT(' Mês de Referência ',(select ds_mes +'/'+cast(cd_ano as varchar) referencia from ST_PERIODO where dt_periodo = data))+'<br>' 
				
				 
				AS HTML
    FROM ST_ALERT_OMC_BMF_01 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Omc Bmf' AS [ALERTAS]
	 ,concat('Omc Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM OMC_BMF_01 a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH PATRIMONIO_CUSTODIA   AS (
    SELECT    CONCAT(' Com posição em ',format(DT_CUSTODIA,'d','pt-br'),' total na carteira ',format(CARTEIRA,'C','pt-br'),' contra o patrimônio ',
				format(PATRIMONIO,'C','pt-br'))+'<br>' 
				 
				AS HTML
    FROM ST_ALERT_PATRIMONIO_CUSTODIA 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Patrimônio X Custódia' AS [ALERTAS]
	 ,concat('Patrimônio X Custódia'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM PATRIMONIO_CUSTODIA  a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH PATRIMONIO_MOVIMENTO    AS (
    SELECT   CONCAT(' Com uma movimentação de entrada de rescursos no valor ',format(VOLUME_CC,'C','pt-br'),' contra o patrimônio ',format(PATRIMONIO,'C','pt-br'))+'<br>'
			
				AS HTML
    FROM ST_ALERT_PATRIMONIO_MOVIMENTO 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Patrimônio X Mov Cc' AS [ALERTAS]
	 ,concat('Patrimônio X Mov Cc'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM PATRIMONIO_MOVIMENTO   a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH PATRIMONIO_MOVIMENTO    AS (
    SELECT   CONCAT(' Com netting BVSP ',format(NETTING_BVSP,'C','pt-br'),' e netting BMF no total ',format(NETTING_BMF,'C','pt-br'),' contra o patrimônio ',
				format(PATRIMONIO,'C','pt-br'))+'<br>'  AS HTML
    FROM ST_ALERT_PATRIMONIO_NETTING 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Patrimônio X Netting' AS [ALERTAS]
	 ,concat('Patrimônio X Netting'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM PATRIMONIO_MOVIMENTO   a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH PATRIMONIO_TRANF_CUST    AS (
    SELECT   CONCAT(' Com transferência de custódia ',format(TOTAL_MES,'C','pt-br'),' contra o patrimônio ',format(PATRIMONIO,'C','pt-br'))+'<br>'
				AS HTML
    FROM ST_ALERT_PATRIMONIO_TRANF_CUST 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Patrimônio X Transf. Custodia' AS [ALERTAS]
	 ,concat('Patrimônio X Transf. Custodia'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM PATRIMONIO_TRANF_CUST   a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH PROCURADOR_02    AS (
    SELECT   CONCAT(' Com uma operação bovespa ',DS_NATUREZA_BVSP,' ou em BMF ',DS_NATUREZA_BMF,' e possui procurador como principal ', IN_PROCUR, 
				' o emitente ',NM_EMIT_ORDEM)+'<br>' AS HTML
    FROM ST_ALERT_PROCURADOR_02 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Procurador' AS [ALERTAS]
	 ,concat('Procurador'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '<br>' + a.HTML 
			    FROM PROCURADOR_02   a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- ;WITH PROCURADOR_02    AS (
--    SELECT   CONCAT(' Com uma operação bovespa ',DS_NATUREZA_BVSP,' ou em BMF ',DS_NATUREZA_BMF,' e possui procurador como principal ', IN_PROCUR, 
--				' o emitente ',NM_EMIT_ORDEM)+'<br>' AS HTML
--    FROM ST_ALERT_PROCURADOR_02 
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE				   AS CD_CLIENTE
--	 ,'Procurador' AS [ALERTAS]
--	 ,concat('Procurador'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '' + a.HTML 
--			    FROM PROCURADOR_02   a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
 ;WITH RANKING_DAYTRADE_BMF     AS (
    SELECT   CONCAT('<br> Com resultado financeiro de',format(RSLT_FIN,'C','pt-br'), ' seu índice de acerto foi de:', CONCAT(CONVERT(VARCHAR,CAST(IND_ACERTO * 100 AS NUMERIC(17,0))), '%')	 , ' e com índice de erro de ',CONCAT(CONVERT(VARCHAR,CAST(IND_ERRO * 100 AS NUMERIC(17,0))), '%')	)+'<br>' 
				 AS HTML
    FROM ST_ALERT_RANKING_DAYTRADE_BMF 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Ranking Daytrade Bmf' AS [ALERTAS]
	 ,concat('Ranking Daytrade Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '<br>' + a.HTML 
			    FROM RANKING_DAYTRADE_BMF    a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH RANKING_DAYTRADE_BVSP     AS (
    SELECT   CONCAT('<br> Com resultado financeiro de',format(RSLT_FIN,'C','pt-br'), ' seu índice de acerto foi de:', CONCAT(CONVERT(VARCHAR,CAST(IND_ACERTO * 100 AS NUMERIC(17,0))), '%')	 , ' e com índice de erro de ',CONCAT(CONVERT(VARCHAR,CAST(IND_ERRO * 100 AS NUMERIC(17,0))), '%')	)+'<br>' 
				 AS HTML
    FROM ST_ALERT_RANKING_DAYTRADE_BVSP 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Ranking Daytrade Bvsp' AS [ALERTAS]
	 ,concat('Ranking Daytrade Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM RANKING_DAYTRADE_BVSP    a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- ;WITH SPOOFING_BOVESPA_02      AS (
--    SELECT  CONCAT(' Com valor anterior ',format(VALOR_ANTES,'C','pt-br'),' e Qtd. cancelada ',format(QT_CANCOF,'#,0','pt-br'),
--				' e valor posterior ', format(VALOR_POS,'C','pt-br'),' e lote médio ', format(LOTE_MEDIO_ANTERIOR,'#,0','pt-br'))+'<br>'
--				AS HTML
--    FROM ST_ALERT_SPOOFING_BOVESPA_02 
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE				   AS CD_CLIENTE
--	 ,'Spoofing' AS [ALERTAS]
--	 ,concat('Spoofing'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '<br>' + a.HTML 
--			    FROM SPOOFING_BOVESPA_02    a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- ;WITH SWING_BMF       AS (
--    SELECT  CONCAT(' Com um resultado de R$',format(RESULTADO,'C','pt-br'),' com média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e o desvio de R$',
--				format(DESVIO,'C','pt-br'))+'<br>' 
--				AS HTML
--    FROM ST_ALERT_SWING_BMF 
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE				   AS CD_CLIENTE
--	 ,'SWINGTRADE BMF' AS [ALERTAS]
--	 ,concat('SWINGTRADE BMF'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '' + a.HTML 
--			    FROM SWING_BMF    a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- ;WITH SWING_BOVESPA        AS (
--    SELECT CONCAT(' Com um resultado de R$',format(RESULTADO,'C','pt-br'),' com média dos últimos 6 meses de R$',format(MEDIA,'C','pt-br'),' e o desvio de R$',
--				format(DESVIO,'C','pt-br'))+'<br>' 
--				AS HTML
--    FROM ST_ALERT_SWING_BOVESPA 
--    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
--) 
--INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
--SELECT @CD_CLIENTE				   AS CD_CLIENTE
--	 ,'SWINGTRADE BVSP' AS [ALERTAS]
--	 ,concat('SWINGTRADE BVSP'
--			 , '</b><br>') 
--			 + STUFF(
--			(
--			    SELECT '<br>' + a.HTML 
--			    FROM SWING_BOVESPA    a
--			    FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH TRANSFERENCIA_FINANCEIRA_01        AS (
    SELECT  CONCAT(' Com um deposito em ',format(DT_DEPOSITO,'d','pt-br'), ' o valor de ', FORMAT(SALDO_CC, 'C', 'pt-br'),' e ficou ', DIAS,
				' dias sem efetuar uma operação.' )+'<br>'  AS HTML
    FROM ST_ALERT_TRANSFERENCIA_FINANCEIRA_01 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Transf. Financeira 01' AS [ALERTAS]
	 ,concat('Transf. Financeira 01'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM TRANSFERENCIA_FINANCEIRA_01    a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION] 
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH TRANSFERENCIA_FINANCEIRA_02         AS (
    SELECT  CONCAT(' Com um deposito em ',format(DT_DEPOSITO,'d','pt-br'),' e retirou em ', format(DT_RETIRADA,'d','pt-br'), ' o valor de ',
				format(TOTAL,'C','pt-br'))  AS HTML
    FROM ST_ALERT_TRANSFERENCIA_FINANCEIRA_02 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Transf. Financeira 02' AS [ALERTAS]
	 ,concat('Transf. Financeira 02'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM TRANSFERENCIA_FINANCEIRA_02     a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
;WITH MONEYPASS_BOVESPA_CORRETORA          AS (
    SELECT CONCAT( 'O cliente apresentou, em operações com a contraparte ' 
,FORMAT(CD_CONTRAPARTE, 'N0', 'pt-BR')
,' nos ativos: ',COALESCE(PAPEIS, N'(não informado)')
,' um resultado de ',format(RESULTADO,'C','pt-br')
,' superior à média dos últimos seis meses ',format(RESULTADO_MEDIA_6M,'C','pt-br')
,', acrescida de ',format(RESULTADO_DESVIO_6M,'C','pt-br')
,' desvios padrão. Além disso, registrou concentração de ',format(CONCENTRACAO,'N2','pt-br')
,'% acima da média histórica de ',format(CONCENTRACAO_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(CONCENTRACAO_DESVIO_6M,'N2','pt-br')
,'%.
O índice de acerto foi de ',format(IND_ACERTO,'N2','pt-br')
,'% e o índice de erro, de ',format(IND_ERRO,'N2','pt-br')
,'%.
Por fim, apresentou intencionalidade de ',format(INTENCIONALIDADE,'N2','pt-br')
,'% comparada à média dos últimos seis meses de ',format(INTENCIONALIDADE_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(INTENCIONALIDADE_DESVIO_6M,'N2','pt-br')
,'%.')+'<br>' AS HTML
    FROM ST_ALERT_MONEYPASS_CORRETORA
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Money Pass Corretora Bvsp'   AS [ALERTAS]
	 ,concat('Money Pass Corretora Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MONEYPASS_BOVESPA_CORRETORA a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH MONEYPASS_CORRETORA_BMF       AS (
    SELECT CONCAT( 'O cliente apresentou, em operações com a contraparte ' 
,FORMAT(CD_CONTRAPARTE, 'N0', 'pt-BR')
,' nos ativos: ',COALESCE(PAPEIS, N'(não informado)')
,' um resultado de ',format(RESULTADO,'C','pt-br')
,' superior à média dos últimos seis meses ',format(RESULTADO_MEDIA_6M,'C','pt-br')
,', acrescida de ',format(RESULTADO_DESVIO_6M,'C','pt-br')
,' desvios padrão. Além disso, registrou concentração de ',format(CONCENTRACAO,'N2','pt-br')
,'% acima da média histórica de ',format(CONCENTRACAO_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(CONCENTRACAO_DESVIO_6M,'N2','pt-br')
,'%.
O índice de acerto foi de ',format(IND_ACERTO,'N2','pt-br')
,'% e o índice de erro, de ',format(IND_ERRO,'N2','pt-br')
,'%.
Por fim, apresentou intencionalidade de ',format(INTENCIONALIDADE,'N2','pt-br')
,'% comparada à média dos últimos seis meses de ',format(INTENCIONALIDADE_MEDIA_6M,'N2','pt-br')
,'% com desvio padrão de ',format(INTENCIONALIDADE_DESVIO_6M,'N2','pt-br')
,'%.')+'<br>' AS HTML
    FROM ST_ALERT_MONEYPASS_CORRETORA_BMF
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Money Pass Corretora Bmf'   AS [ALERTAS]
	 ,concat('Money Pass Corretora Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM MONEYPASS_CORRETORA_BMF a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH OSCILACAO          AS (
    SELECT concat(' No ativo: ', ATIVO,' , obteve Oscilação média de R$',cast(OSCILACAO_MEDIA as money),' com Oscilação max de:',cast(OSCILACAO_MAX as money),' Diferença média de:',cast(DIFERENCA_MEDIA as money))+'<br>'  AS HTML
    FROM ST_ALERT_OSCILACAO 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
)
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Oscilação' AS [ALERTAS]
	 ,concat('Oscilação'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM OSCILACAO     a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH OMG_BOVESPA          AS (
    SELECT concat(' Teve vínculo de: ', VINCULOS,' , com as contrapartes: ',CD_CLIENTE_ENC,' obtendo um resultado de R$:',cast(RESULTADO_OMG as money),' representando uma concentração de negócios com vínculo de:',cast(CONCENTRACAO as money))+'% <br>'  AS HTML
    FROM ST_ALERT_OMG 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
)
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Omg Bvsp' AS [ALERTAS]
	 ,concat('Omg Bvsp'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM OMG_BOVESPA     a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH OMG_BMF          AS (
    SELECT concat(' Teve vínculo de: ', VINCULOS,' , com as contrapartes: ',CD_CLIENTE_ENC,' obtendo um resultado de R$:',cast(RESULTADO_OMG as money),' representando uma concentração de negócios com vínculo de:',cast(CONCENTRACAO as money))+'% <br>'  AS HTML
    FROM ST_ALERT_OMG_BMF 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
)
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Omg Bmf' AS [ALERTAS]
	 ,concat('Omg Bmf'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM OMG_BMF     a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH ATIVO_RESTRITO          AS (
    SELECT concat(' Negociou ', QTDE_ATIVOS, ' ativos, com ', QTDE_NEGOCIOS, ' negócios, são eles: ', NEGOCIOS
    ) + '<br>' AS HTML
    FROM ST_ALERT_ATIVO_RESTRITO
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
) 
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Ativo Restrito'   AS [ALERTAS]
	 ,concat('Ativo Restrito'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM ATIVO_RESTRITO a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 ;WITH EMISSOR_VINCULADO          AS (
    SELECT CONCAT('O cliente ', CD_CLIENTE,
        ' foi enquadrado no alerta de negociação de ativo com vínculo ao emissor em razão da realização de operações envolvendo o ativo ', TICKER,
        ', cujo emissor possui vínculo direto ou indireto com o referido cliente, com o resultado financeiro de ',
        FORMAT(RESULTADO, 'N2', 'pt-br'),
        '.'
    ) + '<br>' AS HTML
    FROM ST_ALERT_EMISSOR_VINCULADO 
    WHERE CD_CLIENTE = @cd_cliente AND data = @dt_alerta
)
INSERT INTO #T1 ([CD_CLIENTE],[ALERTAS],[DESCRIPTION])
SELECT @CD_CLIENTE				   AS CD_CLIENTE
	 ,'Vinculado ao Emissor' AS [ALERTAS]
	 ,concat('Vinculado ao Emissor'
			 , '</b><br>') 
			 + STUFF(
			(
			    SELECT '' + a.HTML 
			    FROM EMISSOR_VINCULADO     a
			    FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS [DESCRIPTION]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

    FETCH NEXT FROM cursor_por_alerta INTO @cd_cliente;
END

CLOSE cursor_por_alerta;
DEALLOCATE cursor_por_alerta;

DELETE FROM  #T1 WHERE DESCRIPTION IS NULL

---##########################################################
	insert into incident_subgroup ([name], group_id, status_id)
	select distinct ALERTAS, 1, 1
	from #T1
	where not exists (
		select * from incident_subgroup where [name] = ALERTAS
	)

	/***********************************************
	faço os insertr na tabela subgrupo com os alertas 
	que os clientes foram alertados. Será carregado N
	subgrupos por conter N combinações
	************************************************/

	IF (SELECT COUNT(1) FROM incident_subgroup) = 0

	BEGIN
	   INSERT INTO incident_subgroup
			SELECT 
		  DISTINCT SUBSTRING(
						COALESCE(
								(SELECT 
							   DISTINCT CAST(ALERTAS AS NVARCHAR(1000)) + ' - ' AS [text()]
								   FROM #T1 AS O
								  WHERE O.CD_CLIENTE = #T1.CD_CLIENTE
						   FOR XML PATH(''), TYPE).value('.[1]', 'NVARCHAR(MAX)'), ''),1,
					 LEN(
						 COALESCE(
								 (SELECT 
								DISTINCT CAST(ALERTAS AS NVARCHAR(1000)) + ' - ' AS [text()]
								   FROM #T1 AS O
								  WHERE O.CD_CLIENTE = #T1.CD_CLIENTE
						   FOR XML PATH(''), TYPE).value('.[1]', 'NVARCHAR(MAX)'), ''))-2) AS NOME
				, 1 group_id
				, 1 statu_id
				,null
			FROM #T1  

	END
	ELSE
	BEGIN

	INSERT INTO incident_subgroup 
			SELECT 
		  DISTINCT SUBSTRING(
							 COALESCE(
									 (SELECT 
									DISTINCT CAST(ALERTAS AS NVARCHAR(1000)) + ' - ' AS [text()]
										FROM #T1 AS O
									   WHERE O.CD_CLIENTE = #T1.CD_CLIENTE
								FOR XML PATH(''), TYPE).value('.[1]', 'NVARCHAR(MAX)'), ''),1,
					 len(
						COALESCE(
								(SELECT 
							   DISTINCT CAST(ALERTAS AS NVARCHAR(1000)) + ' - ' AS [text()]
							   FROM #T1 AS O
							  WHERE O.CD_CLIENTE = #T1.CD_CLIENTE
					   FOR XML PATH(''), TYPE).value('.[1]', 'NVARCHAR(MAX)'), ''))-2) AS NOME
					, 1 GROUP_ID
					, 1 STATU_ID
					, null
				FROM #T1 

				EXCEPT

		  SELECT 
		DISTINCT [NAME]
			   , 1 GROUP_ID
			   , 1 STATU_ID
			   , null
			FROM INCIDENT_SUBGROUP
	END 


--############################################################
	drop table if exists #temp_incident;
	select  @default_summary as summary
		  , '3'				 as area_id
		  , 1				 as priority_id		  
		  , @source_id		 as source_id
		  , @group_id		 as group_id
		  , @reporter_id	 as reporter_id
		  , @assignee_id	 as assignee_id
		  , b.id			 as subgroup_id
		  , @state_id		 as state_id
		  , @reference_id	 as reference_id
		  , a.CD_CLIENTE	 as client_code
		  , c.NM_CLIENTE	 as client_name
		  , c.CD_CPFCGC		 as client_document
		  , a.DESCRIPTION    as description
		  , @date_start		 as date_start
		  , null			 as date_end 
		  , @sla_type	     as sla_type
		  , @sla_time		 as sla_time
		  , 1				 as company_id
		  , 1				 as service_group_id
		  , 'Não informado'  as client_abbreviation
		  , null			 as distribuicaoPropria
		  , null		     as sinacor_client
		  , null			 as broker_code
		  , ALERTAS
		  into #temp_incident
		 from #T1 a 
	left join incident_subgroup b 
		   on a.ALERTAS = b.name
	left join v_cliente_todos c 
		   on a.cd_cliente = c.cd_cliente
	order by a.cd_cliente


	    UPDATE #temp_incident
       SET SINACOR_CLIENT = 1
      FROM #temp_incident A
INNER JOIN V_CLIENTE_TODOS B 
		ON A.CLIENT_CODE = B.CD_CLIENTE
	 WHERE SINACOR_CLIENT IS NULL
	   AND B.FONTE = 'SINACOR'

    UPDATE #temp_incident
       SET SINACOR_CLIENT = 0
	 WHERE NOT EXISTS (SELECT 1 
						 FROM V_CLIENTE_TODOS B 
						WHERE #temp_incident.CLIENT_CODE = B.CD_CLIENTE AND FONTE = 'SINACOR')
	   AND SINACOR_CLIENT IS NULL

	   		update #temp_incident
			set broker_code = (select max(CD_PARAMETRO) from ST_CLIENTE_PARAMETROS where DS_PARAMETRO = 'CD_CONTRAPARTE')
			where broker_code is null 

	
			--insert into incident 
			--insert into incident(summary,area_id,priority_id,source_id,group_id,reporter_id,assignee_id,subgroup_id,state_id,reference_id,client_code,client_name,client_document,description,date_start,date_end,sla_type,sla_time,company_id,service_group_id,client_abbreviation,distribuicaoPropria,sinacor_client,broker_code)
		
			drop table if exists #T1a;
				select 
			  distinct client_code
					 , description 
					 , a.ALERTAS
					 ,descrição
				
					 ,replace(replace(replace(replace(b.Exigencia,'Exigência Regulatória -',''),'- Regras de SBR - Produtos e Serviços',''),'e atualizações posteriores',''),'Regras de SBR - Identificação e Qualificação do Cliente','')Exigencia
					 ,inciso
					 into #T1a
				  from #temp_incident a 
				  left join (select Exigencia
								  ,inciso
								  ,[ALERTA FIRA]
								  ,replace(replace(DESCRIÇÃO,'Mudança Repentina -  Bovespa','Mudança Repentina'),'Mudança Repentina - BM&F','Mudança Repentina')DESCRIÇÃO 
								  from ST_INCISOS 
								  where  descrição not in  ('Patrimônio versus Volumes em Renda Fixa ','Patrimônio versus Posição em Clubes e Fundos de Investimentos ') 
								  
								) b on a.alertas = b.[ALERTA FIRA]
					
								
				drop table if exists #T2a;
				select 
			   distinct client_code
					  , description
					  , descrição
					  , '<br>'+Exigencia+' '+STUFF((SELECT 
												  DISTINCT '	' + inciso 
													  FROM #T1a x
													 where x.Exigencia = a.Exigencia and x.client_code = a.client_code and x.Inciso = a.Inciso and x.ALERTAS = a.ALERTAS and x.description = a.description and a.description = x.description
													FOR XML PATH(''), TYPE
						).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as Exi_inci
						,ALERTAS AS NOME
						into #T2a
					FROM #T1a A
					
		
			
	
	drop table if exists #T3a;
	         SELECT 
	       DISTINCT t.client_code
	       		 , '<b>'+descrição+'</b>'+' '+STUFF((SELECT DISTINCT '  ' + a.Exi_inci
	       	 FROM #t2a a
	       	WHERE a.client_code = t.client_code and a.descrição = t.descrição 
	       	FOR XML PATH(''), TYPE
	       	).value('.', 'NVARCHAR(MAX)'), 1, 2, '')+    replace(substring(t.description,charindex('</b>'  , t.description ),len(description)),'</b>','')+'<br><br>' description
	       , nome alerta
	       into #T3a
	       	FROM(SELECT DISTINCT client_code, description, descrição, nome FROM #t2a) t
		

		
	 --DROP TABLE IF EXISTS #T4A;
		--	SELECT 
		--		t.client_code,
		--		STUFF((SELECT '<br>' + a.description
		--			   FROM #T3a a
		--			   WHERE a.client_code = t.client_code
		--			   FOR XML PATH(''), TYPE
		--			   ).value('.', 'NVARCHAR(MAX)'), 1, 0, '') AS description
		--	INTO #T4A
		--	FROM (SELECT DISTINCT client_code FROM #T3a) t
		--ORDER BY t.client_code 

		--SELECT * FROM #T3a

	DROP TABLE IF EXISTS #incident_subgroup;
		   SELECT 
		 DISTINCT CD_CLIENTE 
			 , ALERTAS as subgroup
		into #incident_subgroup
		FROM #T1 
	
	
	drop table if exists #incident_subgroup_id;
		   select a.CD_CLIENTE
			    , b.id 
				,b.name alerta
		     into #incident_subgroup_id
		     from #incident_subgroup a 
		left join incident_subgroup b 
		       on a.subgroup = b.name

	
	drop table if exists #temp_incident_article_subparagraph;
		   select 
		distinct STUFF((SELECT 
					  DISTINCT ' - ' + replace(Exi_inci,'<br>','')  
						  FROM #t2a x
						 where x.client_code = a.client_code AND X.DESCRIÇÃO = A.DESCRIÇÃO
						FOR XML PATH(''), TYPE
										).value('.', 'NVARCHAR(MAX)'), 1, 2, '') subparagraph
										,nome subgrupo
					into #temp_incident_article_subparagraph
					from #t2a a --incident_article_subparagraph


	insert into incident_article_subparagraph(subparagraph)
			     select 
			   distinct subparagraph 
				   from #temp_incident_article_subparagraph a 
				  where not exists (select 1 from incident_article_subparagraph b where a.subparagraph = b.subparagraph)
				  and subparagraph <> 'null'-- n pode ser null
				  

	 drop table if exists #update_inciso;
			select 
		  distinct c.subparagraph
				 , c.id 
				 , a.subgrupo 
				 , b.name 
			  into #update_inciso
			  from #temp_incident_article_subparagraph	a 
		 left join incident_subgroup b
			    on a.subgrupo = b.name 
		 left join incident_article_subparagraph c 
			    on a.subparagraph = c.subparagraph

		     update incident_subgroup
				set subparagraph_id = b.id
			   from incident_subgroup a 
		 inner join #update_inciso b
			     on a.name = b.subgrupo
			  where subparagraph_id is null

		
	
			insert into incident (summary, area_id, priority_id, source_id, group_id, reporter_id, assignee_id, subgroup_id, state_id, reference_id, client_code, client_name, client_document, description, date_start, date_end, sla_type, sla_time, company_id, service_group_id, client_abbreviation, distribuicaoPropria, sinacor_client, broker_code, code_88, cvm_code)
			
				select 
			  distinct summary
					 ,area_id
					 ,priority_id
					 ,source_id
					 ,group_id
					 ,reporter_id
					 ,assignee_id
					 ,c.id subgroup_id
					 ,state_id
					 ,reference_id
					 ,a.client_code
					 ,client_name
					 ,client_document
					 ,B.description
					 ,date_start
					 ,date_end
					 ,sla_type
					 ,sla_time
					 ,company_id
					 ,service_group_id
					 ,client_abbreviation
					 ,distribuicaoPropria
					 ,sinacor_client
					 ,broker_code
					 ,null code_88
					 ,null cvm_code
			
				from #temp_incident a
		  inner join #T3A B
				  on a.client_code = B.client_code					
		  inner join #incident_subgroup_id c 
			      on a.client_code = c.cd_cliente
			     and b.alerta = c.alerta
		
	
		
			

    -- ================================================
    -- Marca DT_FIRA para registros carregados (fallback)
    -- ================================================
    DECLARE @__dt_fira_now DATETIME = GETDATE();
    IF COL_LENGTH(N'dbo.REFERENCIA', 'DT_FIRA') IS NOT NULL
    BEGIN
        UPDATE [dbo].[REFERENCIA]
        SET DT_FIRA = @__dt_fira_now
        WHERE DT_FIRA IS NULL;
    END

    IF COL_LENGTH(N'dbo.incident_subgroup', 'DT_FIRA') IS NOT NULL
    BEGIN
        UPDATE [dbo].[incident_subgroup]
        SET DT_FIRA = @__dt_fira_now
        WHERE DT_FIRA IS NULL;
    END

    IF COL_LENGTH(N'dbo.incident', 'DT_FIRA') IS NOT NULL
    BEGIN
        UPDATE [dbo].[incident]
        SET DT_FIRA = @__dt_fira_now
        WHERE DT_FIRA IS NULL;
    END

    IF COL_LENGTH(N'dbo.incident_article_subparagraph', 'DT_FIRA') IS NOT NULL
    BEGIN
        UPDATE [dbo].[incident_article_subparagraph]
        SET DT_FIRA = @__dt_fira_now
        WHERE DT_FIRA IS NULL;
    END
end