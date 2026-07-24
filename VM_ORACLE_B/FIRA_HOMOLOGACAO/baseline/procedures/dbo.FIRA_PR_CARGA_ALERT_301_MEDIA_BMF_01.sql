/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_301_MEDIA_BMF_01]    Script Date: 25/02/2026 15:50:21 ******/
CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_MEDIA_BMF_01] @PREGAO SMALLDATETIME, @AUX INT
--WITH RECOMPILE
AS

--DELETE FROM #CLI comentado por Heitor e Saulo e AND B.MEDIA >= 1 adicionado em 25/05/26
/*************************************************************************************************
REGRA DO ALERTA:
Qtd Contratos mês > média 6 meses + 3 desvios padrão
Qtd Contratos mês (pf/pj) > Q3 + (1.5 * IQR)
Onde: IQR (intervalo Interquartil) e Q3 (terceiro quartil)
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_MEDIA_BMF_01_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_MEDIA_BMF_01_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[VOLUME] [float] NULL,
	[MEDIA] [float] NULL,
	[DESVIO] [float] NULL,
	[COMMOD_TOTAL] [varchar](1000) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_MEDIA_BMF_01_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_MEDIA_BMF_01',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260305'
--SET @AUX = (SELECT DAY(@PREGAO))
 
declare @dt_ini date = dateadd(month, datediff(month,0, dateadd(month,-1,@pregao)),0) -- 1 dia do mes atual
declare @dt_fim date = dateadd(month,1,@dt_ini) -- ultimo dia do mes atual
declare @dt_ini_6m date = dateadd(month, datediff(month,0, dateadd(month,-7,@pregao)),0) -- primeiro dia do 6 mes anterior ao mes atual
declare @dt_fim_6m date = @dt_ini -- 1 dia do mes atual


-- CLIENTES 
drop table if exists #CLIENTEPJ
SELECT DISTINCT CD_CLIENTE, DT_CRIACAO INTO #CLIENTEPJ FROM ST_DADOS_BASICOS_PJ
drop table if exists #CLIENTEPF
SELECT DISTINCT CD_CLIENTE, DT_CRIACAO INTO #CLIENTEPF FROM ST_DADOS_BASICOS_PF

-- VOLUME MÊS
drop table if exists #MBMF
SELECT 
    CD_CLIENTE,
    SUM(QT_QTDDET) AS VOLUME,
    SUM(ISNULL(PR_NEGOCIO * QT_QTDDET, 0)) AS VOL_MES_ATUAL
INTO #MBMF
FROM ST_BMF_NEGOCIOS_NC
WHERE DT_NEGOCIO >= @dt_ini
  AND DT_NEGOCIO < @dt_fim
  AND TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
GROUP BY CD_CLIENTE

-- PF
drop table if exists #MBMF_PF
SELECT MB.CD_CLIENTE, MB.VOLUME INTO #MBMF_PF
FROM #MBMF MB JOIN #CLIENTEPF PF ON MB.CD_CLIENTE = PF.CD_CLIENTE

drop table if exists #QUARTIL_PF
SELECT 'PF' AS TIPO_CLIENTE, Q1, Q3, (Q3 - Q1) AS IQR, (Q3 + 1.5 * (Q3 - Q1)) AS LIMITE_SUPERIOR_PF
INTO #QUARTIL_PF
FROM (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY VOLUME) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY VOLUME) OVER () AS Q3
    FROM #MBMF_PF
) Q

-- PJ
drop table if exists #MBMF_PJ
SELECT MB.CD_CLIENTE, MB.VOLUME INTO #MBMF_PJ
FROM #MBMF MB JOIN #CLIENTEPJ PJ ON MB.CD_CLIENTE = PJ.CD_CLIENTE

drop table if exists #QUARTIL_PJ
SELECT 'PJ' AS TIPO_CLIENTE, Q1, Q3, (Q3 - Q1) AS IQR, (Q3 + 1.5 * (Q3 - 1)) AS LIMITE_SUPERIOR_PJ
INTO #QUARTIL_PJ
FROM (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY VOLUME) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY VOLUME) OVER () AS Q3
    FROM #MBMF_PJ
) Q

-- HISTÓRICO 6 MESES
drop table if exists #MBMF_MEDIA
SELECT CD_CLIENTE, 
       AVG(VOLUME) AS MEDIA, 
       STDEV(VOLUME) AS DESVIO
INTO #MBMF_MEDIA
FROM (
    SELECT 
        CD_ANOMES, CD_CLIENTE, SUM(QT_QTDDET) AS VOLUME
    FROM ST_BMF_NEGOCIOS_NC A
    INNER JOIN ST_PERIODO D ON A.DT_NEGOCIO = D.DT_PERIODO
    WHERE DT_NEGOCIO >= @dt_ini_6m
	AND DT_NEGOCIO < @dt_fim_6m
      AND TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
    GROUP BY CD_ANOMES, CD_CLIENTE
) X
GROUP BY CD_CLIENTE

-- COMMODITIES (ATIVOS)
drop table if exists #TOTAL_COMMOD
SELECT DISTINCT CD_CLIENTE, CONCAT(CD_COMMOD,ISNULL(CD_SERIE,'')) AS CD_COMMOD, SUM(QT_QTDDET) AS VOLUME
INTO #TOTAL_COMMOD
FROM ST_BMF_NEGOCIOS_NC
WHERE DT_NEGOCIO >= @dt_ini
  AND DT_NEGOCIO < @dt_fim
  AND TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
GROUP BY CD_CLIENTE, CD_COMMOD, CD_SERIE;


drop table if exists #TOTAL_COMMOD2
SELECT CD_CLIENTE, 
       STUFF((
        SELECT ', ' + P.CD_COMMOD
        FROM #TOTAL_COMMOD P
        WHERE P.CD_CLIENTE = A.CD_CLIENTE
        ORDER BY P.VOLUME DESC
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS COMMOD_TOTAL
INTO #TOTAL_COMMOD2
FROM #TOTAL_COMMOD A
GROUP BY CD_CLIENTE

--
drop table if exists #CLI
SELECT DISTINCT
    CAST(@PREGAO - @AUX AS DATE) AS DATA,
    A.CD_CLIENTE,
    C.DT_CRIACAO AS DT_CRIACAO_GERAL,
    PJ.DT_CRIACAO AS DT_CRIACAO_PJ,
    PF.DT_CRIACAO AS DT_CRIACAO_PF,
    CASE 
        WHEN YEAR(CAST(@PREGAO - @AUX AS DATE)) * 100 + MONTH(CAST(@PREGAO - @AUX AS DATE)) = 
             YEAR(C.DT_CRIACAO) * 100 + MONTH(C.DT_CRIACAO) 
        THEN 'SIM' ELSE 'NAO' 
    END AS MESMO_MES,
    DATEDIFF(M, C.DT_CRIACAO, CAST(@PREGAO - @AUX AS DATE)) AS MESES,
    A.VOLUME,
    B.MEDIA,
    ISNULL(B.DESVIO, 0) AS DESVIO,
    T.COMMOD_TOTAL,
    VOL_MES_ATUAL,
    QPF.LIMITE_SUPERIOR_PF,
    QPJ.LIMITE_SUPERIOR_PJ
INTO #CLI
FROM #MBMF A
JOIN #MBMF_MEDIA B ON A.CD_CLIENTE = B.CD_CLIENTE
LEFT JOIN (SELECT DISTINCT AA.* FROM #CLIENTEPF AA 
		    UNION ALL
		   SELECT DISTINCT BB.* FROM #CLIENTEPJ BB) C ON A.CD_CLIENTE = C.CD_CLIENTE
LEFT JOIN #CLIENTEPJ PJ ON A.CD_CLIENTE = PJ.CD_CLIENTE
LEFT JOIN #CLIENTEPF PF ON A.CD_CLIENTE = PF.CD_CLIENTE
LEFT JOIN #TOTAL_COMMOD2 T ON A.CD_CLIENTE = T.CD_CLIENTE
LEFT JOIN #QUARTIL_PF QPF ON PF.CD_CLIENTE IS NOT NULL AND 1 = 1
LEFT JOIN #QUARTIL_PJ QPJ ON PJ.CD_CLIENTE IS NOT NULL AND 1 = 1
WHERE A.VOLUME > ISNULL(B.MEDIA, 0) + (ISNULL(B.DESVIO, 0) * 3)
  AND (
      (PF.CD_CLIENTE IS NOT NULL AND A.VOLUME > ISNULL(LIMITE_SUPERIOR_PF, 0))
      OR
      (PJ.CD_CLIENTE IS NOT NULL AND A.VOLUME > ISNULL(LIMITE_SUPERIOR_PJ, 0))
  )
  AND B.MEDIA >= 1

--EXCLUINDO TODOS OS CLIENTES RECEM CRIADOS EOU CLIENTES COM APENAS 2MESES DE OPERACAO ONDE O DESVIO É ZERO-- 
--DELETE FROM #CLI WHERE MESES IN (0,1,2) AND DESVIO >= 0

-- FINAL
--delete em caso de reprocessamento.  
DELETE FROM ST_ALERT_MEDIA_BMF_01 WHERE DATA = CAST(@PREGAO - @AUX AS DATE)

----insert do alerta final   
INSERT INTO ST_ALERT_MEDIA_BMF_01 (DATA,CD_CLIENTE,VOLUME,MEDIA,DESVIO,COMMOD_TOTAL)
SELECT CAST(@PREGAO - @AUX AS DATE) DATA
	,CD_CLIENTE
	,VOLUME						--AS [QTD. CONTRATO MÊS]
	,MEDIA						--AS [MÉDIA VOLUME 6M]
	,ISNULL(DESVIO,0) AS DESVIO	--[DESVIO VOLUME 6M]
	,COMMOD_TOTAL				--AS [TOTAL DE COMMODITIES]
	--,VOL_MES_ATUAL			--AS [VALOR AJUSTE MÊS]
FROM #CLI
ORDER BY CD_CLIENTE
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_MEDIA_BMF_01', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_MEDIA_BMF_01
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_MEDIA_BMF_01_PADRAO