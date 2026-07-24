CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_08_CHURNING_BOVESPA_02] @PREGAO SMALLDATETIME, @AUX INT
as


/*************************************************************************************************
REGRA DO ALERTA:
Turnover Ratio (TR): Fórmula:
(Total de Compras / Carteira Média) * (Número de dias úteis do semestre / Número de dias úteis do mês)
Cost-Equity Ratio (CE): Fórmula:
(Corretagem / Carteira Média) * (Número de dias úteis do semestre / Número de dias úteis do mês)
Condição de Alerta:
Se TR for maior que 2, um alerta é acionado
CE for maior ou igual a 11,2%, um alerta é acionado.
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
CREATE TABLE [dbo].[ST_ALERT_CHURNING_BOVESPA_02_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[QTD] [int] NULL,
	[CORRETAGEM] [numeric](20, 2) NULL,
	[TURNOVER_RATIO] [numeric](20, 2) NULL,
	[COST_EQUITY_RATIO] [numeric](20, 2) NULL,
	[ALERTADO_TR] [varchar](10) NULL,
	[ALERTADO_CE] [varchar](10) NULL,
	[VOLUME_COMPRA] [float] NULL,
	[QTD_DIA_UTEIS_MES] [int] NULL,
	[QTD_DIA_UTEIS_SEMESTRE] [int] NULL,
	[MED_CARTEIRA] [numeric](17, 2) NULL,
	[ATIVO] [nvarchar](max) NULL,
	[RESULTADO] [float] NULL,
	[NM_CLIENTE] [varchar](400) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY];
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
-- Executar de verdade (automático)
EXEC dbo.usp_sync_table_schema_add_alter_2012
     @schema_name='dbo',
     @base_table='ST_ALERT_CHURNING_BOVESPA_02',
     @execute=1,
     @allow_drop=1,
     @apply_rename_map=1;

	 
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))
 

DELETE FROM ST_ALERT_CHURNING_BOVESPA_02 WHERE DATA = DATEADD(DAY,-@AUX,@PREGAO);
 
/*--------------------------------------------------------------
-- 1) Datas de trabalho
--------------------------------------------------------------*/
DECLARE @DtIni  date ,      -- 1.º dia do mês pesquisado
        @DtFim  date ,      -- último dia do mês pesquisado
        @DtIniSemestre date,/* 1.º dia do 6.º mês anterior   */
        @DtFimSemestre date;/* último dia do mês anterior    */

-- ponto de partida: mês que você passou via @CD_ANO / @DS_MES
SELECT
    @DtIni = MIN(DT_PERIODO),
    @DtFim = MAX(DT_PERIODO)
FROM ST_PERIODO
WHERE CD_ANO = year(eomonth(@pregao,-1))
  AND cd_MES = month(eomonth(@pregao,-1))

-- janela de 7 meses anteriores
SET @DtIniSemestre = DATEADD(MONTH, -6, @DtIni);   -- ex.: 2023-10-01
SET @DtFimSemestre = DATEADD(DAY , 0,  @DtFim);   -- ex.: 2024-03-31

/*--------------------------------------------------------------
-- 1.2) Contagem dos dias úteis
--------------------------------------------------------------*/
DECLARE
    @DiasUteisMes      int,
    @DiasUteisSemestre int;

SELECT
    @DiasUteisMes = SUM(
        CASE WHEN P.DT_PERIODO BETWEEN @DtIni AND @DtFim
              AND P.DT_FERIADO   = 'NAO'
              AND P.DS_DIASEMANA NOT IN ('SABADO','DOMINGO')
             THEN 1 END),

    @DiasUteisSemestre = SUM(
        CASE WHEN P.DT_PERIODO BETWEEN @DtIniSemestre AND @DtFimSemestre
              AND P.DT_FERIADO   = 'NAO'
              AND P.DS_DIASEMANA NOT IN ('SABADO','DOMINGO')
             THEN 1 END)
FROM ST_PERIODO AS P
WHERE P.DT_PERIODO BETWEEN @DtIniSemestre AND @DtFim;  -- restringe o scan

 
/* ------------------------------------------------------------------
   2) Média de 6 meses (180 dias) — já filtrada ou não por cliente
------------------------------------------------------------------ */
;WITH Carteira180 AS (
    SELECT
        CD_CLIENTE,
        AVG(CAST(MED_CARTEIRA AS decimal(15,2))) AS MED_CARTEIRA
    FROM ST_CARTEIRA_MEDIA_MENSAL
    WHERE CD_ANOMES BETWEEN FORMAT(DATEADD(MONTH,-6,@DtIni),'yyyyMM')
                        AND FORMAT(EOMONTH(DATEADD(MONTH,-1,@DtIni)),'yyyyMM')
 
    GROUP BY CD_CLIENTE
)

/* ------------------------------------------------------------------
   3) Agregação única sobre ST_CORRETAGEM_ORDEM
------------------------------------------------------------------ */
, OrdemAgregada AS (
    SELECT
        CD_CLIENTE,
        CD_PAPEL,

        -- métricas separadas (evita repetir SUM/AVG)
        SUM(CASE WHEN CD_NATOPE='C' THEN QT_MULTIPLICADOR ELSE 0 END) AS QtC,
        SUM(CASE WHEN CD_NATOPE='V' THEN QT_MULTIPLICADOR ELSE 0 END) AS QtV,

        SUM(CASE WHEN CD_NATOPE='C' THEN VL_TOTNEG      ELSE 0 END) AS VolC,
        SUM(CASE WHEN CD_NATOPE='V' THEN VL_TOTNEG      ELSE 0 END) AS VolV,

        isnull(AVG(CASE WHEN CD_NATOPE='C' THEN VL_NEGOCIO END),0)             AS PrecoMedioC,
        isnull(AVG(CASE WHEN CD_NATOPE='V' THEN VL_NEGOCIO END),0)             AS PrecoMedioV,

        SUM(VL_CORTOT_ORI)                                           AS Corretagem,
        COUNT(*)                                                     AS QtOper
    FROM ST_CORRETAGEM_ORDEM  WITH (NOLOCK)   -- retire NOLOCK se precisa de consistência
    WHERE  DT_NEGOCIO BETWEEN @DtIni AND @DtFim
      AND CD_NATOPE IN ('C','V')
    GROUP BY CD_CLIENTE, CD_PAPEL
)

/* ------------------------------------------------------------------
   5) pego somente o que preciso dos dados basicos
------------------------------------------------------------------ */
,#v_Cliente_todos as (
select distinct cd_cliente,nm_cliente,cd_cpfcgc 
from ST_DADOS_BASICOS_PF
union all
select distinct cd_cliente,nm_cliente,cd_cpfcgc 
from ST_DADOS_BASICOS_Pj
)



/* ------------------------------------------------------------------
   5) Resultado final
------------------------------------------------------------------ */
,resultadoFinal as (
SELECT
    upper(FORMAT(@DtIni, N'yyyy ''/'' MMMM', 'pt-BR')) AS [Referencia],
    O.CD_CLIENTE as [Cod do Cliente],
    C.NM_CLIENTE as [Nome do Cliente],
    C.CD_CPFCGC as [CPF/CNPJ],
    O.CD_PAPEL as [Ativo],
	(ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0) *
                              (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))) AS [Turnover Ratio],

    CASE
                                    WHEN (ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
                                    * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))) <= 2
                                    THEN 'NÃO'
                                    WHEN (ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
                                    * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))) > 8
                                    THEN 'PROVÁVEL' ELSE 'POSSÍVEL' END AS [Alertado TR],

	(ISNULL(ISNULL(CAST(O.Corretagem AS NUMERIC(12,5)),0) /  NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
      * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0)))  AS [Cost Equity Ratio],

	CASE WHEN (ISNULL(ISNULL(CAST(O.Corretagem AS NUMERIC(15,2)),0) /  NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
                  * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0)))  < 11.2 THEN 'NÃO' ELSE 'SIM' END AS [Alertado CE],

    /* lógica de resultado simplificada */
	case when 		 
			 (case when qtc = 0 then qtv else qtc end) > (case when qtv = 0 then qtc else qtv end) then
		   (case when qtv = 0 then qtc else qtv end) else (case when qtc = 0 then qtv else qtc end) end *
	     (isnull(O.PrecoMedioV,0) - isnull(O.PrecoMedioC,0)) AS [Resultado],

    O.Corretagem as Corretagem ,
    O.VolC AS [Volume Compra],
    ISNULL(M.MED_CARTEIRA,0) AS [Carteira Med 6M],
    O.QtOper        AS [Qtd de Operacoes],
    @DiasUteisSemestre   AS [Dias Uteis Semestre],
    @DiasUteisMes   AS [Dias Uteis Mes]

FROM OrdemAgregada     AS O
LEFT JOIN Carteira180  AS M ON M.CD_CLIENTE = O.CD_CLIENTE
LEFT JOIN #V_CLIENTE_TODOS  C ON C.CD_CLIENTE = O.CD_CLIENTE
)



----query final alerta
insert into ST_ALERT_CHURNING_BOVESPA_02 
(DATA,CD_CLIENTE,QTD,CORRETAGEM,TURNOVER_RATIO,COST_EQUITY_RATIO,ALERTADO_TR,ALERTADO_CE,VOLUME_COMPRA,
QTD_DIA_UTEIS_MES,QTD_DIA_UTEIS_SEMESTRE,MED_CARTEIRA,ATIVO,RESULTADO,NM_CLIENTE)
 
 SELECT 
 cast (@pregao - @aux as date) as referencia
 ,a.[cod do cliente]
 ,sum([qtd de operacoes]) as [qtd de operacoes]
 ,sum(Corretagem) as corretagem
 ,(ISNULL(cast(sum([volume Compra]) as decimal(38,5)) / NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0) *
    (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0))) AS [Turnover Ratio]

 ,(ISNULL(ISNULL(CAST(sum(Corretagem) AS NUMERIC(12,5)),0) /  NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
      * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0)))  AS [Cost Equity Ratio]
 ,CASE
    WHEN (ISNULL(cast(sum([volume Compra]) as decimal(38,5)) / NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
    * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0))) <= 2
    THEN 'NÃO'
    WHEN (ISNULL(cast(sum([volume Compra]) as decimal(38,5)) / NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
    * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0))) > 8
    THEN 'PROVÁVEL' ELSE 'POSSÍVEL' END AS [Alertado TR]
 ,CASE WHEN (ISNULL(ISNULL(CAST(sum(Corretagem) AS NUMERIC(15,2)),0) /  NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
                  * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0)))  < 11.2 THEN 'NÃO' ELSE 'SIM' END AS [Alertado CE]

 ,sum([volume Compra]) as [volume Compra]
 ,max([Dias Uteis Mes]) as [Dias Uteis Mes]
 ,max([Dias Uteis Semestre]) as [Dias Uteis Semestre]
 ,max([Carteira Med 6M]) as [Carteira Med 6M]
 ,STUFF((
    SELECT ', ' + ativo
    FROM resultadoFinal x
    WHERE x.referencia       = a.referencia
      AND x.[cod do cliente] = a.[cod do cliente]
      AND x.[nome do cliente]= a.[nome do cliente]
    FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, '') as ativo
 ,sum(resultado) as resultado
 ,a.[nome do cliente]
 FROM resultadoFinal A

--where a.[cod do cliente] = 104530  

group by a.referencia,a.[cod do cliente],a.[nome do cliente]
having CASE WHEN (ISNULL(ISNULL(CAST(sum(Corretagem) AS NUMERIC(15,2)),0) /  NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
                  * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0)))  < 11.2 THEN 'NÃO' ELSE 'SIM' END <> 'Não'
		and
		CASE
                                    WHEN (ISNULL(cast(sum([volume Compra]) as decimal(38,5)) / NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
                                    * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0))) <= 2
                                    THEN 'NÃO'
                                    WHEN (ISNULL(cast(sum([volume Compra]) as decimal(38,5)) / NULLIF(cast(ISNULL(max([Carteira Med 6M]),0) as decimal(38,5)),0),0)
                                    * (cast(max([Dias Uteis Semestre]) as float) / NULLIF(cast(max([Dias Uteis Mes]) as float),0))) > 8
                                    THEN 'PROVÁVEL' ELSE 'POSSÍVEL' END <> 'Não'


/******* fim do processo de carga do alerta **********/
/* ================================================
  Marca DT_FIRA para registros carregados (fallback)
  ================================================*/
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_CHURNING_BOVESPA_02', 'DT_FIRA') IS NOT NULL
BEGIN
     UPDATE [dbo].[ST_ALERT_CHURNING_BOVESPA_02]
     SET DT_FIRA = @__dt_fira_now
     WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE ST_ALERT_CHURNING_BOVESPA_02_PADRAO