CREATE   PROCEDURE [dbo].[PR_CHURNING] @CD_ANO INT, @DS_MES VARCHAR(20),@CD_CLIENTE int,@CD_PAPEL     varchar(30),@QTDPORPAGINA  INT ,@PAGINA INT
--WITH ENCRYPTION
AS



/* parâmetros (passe NULL quando quiser “tudo”) */
--DECLARE @CD_ANO INT, @DS_MES VARCHAR(20) ,@QTDPORPAGINA  INT = 100 ,@PAGINA INT =1 ;
--SET @CD_ANO = 2024;
--SET @DS_MES = 'ABRIL';
--DECLARE @CD_CLIENTE   int          = '104530';
--DECLARE @CD_PAPEL     varchar(30)  = '';

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
WHERE CD_ANO = @CD_ANO
  AND DS_MES = @DS_MES

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
      AND (@CD_CLIENTE = '' OR CD_CLIENTE = @CD_CLIENTE)
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
    WHERE (@CD_CLIENTE ='' OR CD_CLIENTE = @CD_CLIENTE)
      AND (@CD_PAPEL ='' OR CD_PAPEL   = @CD_PAPEL)
      AND DT_NEGOCIO BETWEEN @DtIni AND @DtFim
      AND CD_NATOPE IN ('C','V')
    GROUP BY CD_CLIENTE, CD_PAPEL
)

/* ------------------------------------------------------------------
   4) Resultado final
------------------------------------------------------------------ */
--,resultadoFinal as (
SELECT
    upper(FORMAT(@DtIni, N'yyyy ''/'' MMMM', 'pt-BR')) AS [Referencia],
    O.CD_CLIENTE as [Cod do Cliente],
    C.NM_CLIENTE as [Nome do Cliente],
    C.CD_CPFCGC as [CPF/CNPJ],
    O.CD_PAPEL as [Ativo],
	--format((ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0) *
 --                             (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))),'f','pt-br') AS [Turnover Ratio],

 --   CASE
 --                                   WHEN (ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
 --                                   * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))) < 2
 --                                   THEN 'NÃO'
 --                                   WHEN (ISNULL(cast(o.VolC as decimal(38,5)) / NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
 --                                   * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))) > 8
 --                                   THEN 'PROVÁVEL' ELSE 'POSSÍVEL' END AS [Alertado TR],

	--format((ISNULL(ISNULL(CAST(O.Corretagem AS NUMERIC(12,5)),0) /  NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
 --     * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0))),'f','pt-br')  AS [Cost Equity Ratio],

	--CASE WHEN (ISNULL(ISNULL(CAST(O.Corretagem AS NUMERIC(15,2)),0) /  NULLIF(cast(ISNULL(M.MED_CARTEIRA,0) as decimal(38,5)),0),0)
 --                 * (cast(@DiasUteisSemestre as float) / NULLIF(cast(@DiasUteisMes as float),0)))  < 21 THEN 'NÃO' ELSE 'SIM' END AS [Alertado CE],

    /* lógica de resultado simplificada */
	format(case when 		 
			 (case when qtc = 0 then qtv else qtc end) > (case when qtv = 0 then qtc else qtv end) then
		   (case when qtv = 0 then qtc else qtv end) else (case when qtc = 0 then qtv else qtc end) end *
	     (isnull(O.PrecoMedioV,0) - isnull(O.PrecoMedioC,0)),'f','pt-br') AS [Resultado],

    format(O.Corretagem,'f','pt-br') as Corretagem ,
    format(O.VolC,'f','pt-br') AS [Volume Compra],
    format(ISNULL(M.MED_CARTEIRA,0),'f','pt-br') AS [Carteira Med 6M],
    O.QtOper        AS [Qtd de Operacoes],
    @DiasUteisSemestre   AS [Dias Uteis Semestre],
    @DiasUteisMes   AS [Dias Uteis Mes]

FROM OrdemAgregada     AS O
LEFT JOIN Carteira180  AS M ON M.CD_CLIENTE = O.CD_CLIENTE
LEFT JOIN V_CLIENTE_TODOS  C ON C.CD_CLIENTE = O.CD_CLIENTE

ORDER BY O.CD_CLIENTE        
OFFSET (ISNULL(@PAGINA,1) - 1) * CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS
FETCH NEXT CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS ONLY;

 
/***********DESATIVADO EM 21/06/2025 - FLAVIO

      
--    DECLARE @CD_ANO INT, @DS_MES VARCHAR(20),@CD_CLIENTE VARCHAR(160),@QTDPORPAGINA  INT ,@PAGINA INT ;
--SET @CD_ANO = 2023;
--SET @DS_MES = 'dezembro';
--SET @CD_CLIENTE = '551746'


      DECLARE @DT_INICIO SMALLDATETIME = (SELECT MIN(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES);
      DECLARE @DT_FIM    SMALLDATETIME = (SELECT MAX(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES);
      
      DECLARE @QTD_DIA_UTEIS_MES INT = (SELECT COUNT(1) QTD FROM ST_PERIODO
                                                                  WHERE DT_PERIODO >= @DT_INICIO AND DT_PERIODO <= @DT_FIM AND DT_FERIADO = 'NAO'AND DS_DIASEMANA NOT IN ('SABADO','DOMINGO'))
                                    
      DECLARE @QTD_DIA_UTEIS_ANO INT = (SELECT COUNT(1) QTD FROM ST_PERIODO
                                                               WHERE DT_PERIODO >= DATEADD(M,-12,@DT_INICIO) AND DT_PERIODO <= @DT_FIM  AND DT_FERIADO = 'NAO' AND DS_DIASEMANA NOT IN ('SABADO','DOMINGO'));
      


      DECLARE @CD_ANOMES_INICIO_180 INT,@CD_ANOMES_FIM_180 INT, @CD_ANOMES int
      SET @CD_ANOMES = (SELECT TOP 1 YEAR(EOMONTH(DT_PERIODO,0))*100 + MONTH(EOMONTH(DT_PERIODO,0)) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES)
      SET @CD_ANOMES_INICIO_180 = (SELECT TOP 1 YEAR(EOMONTH(DT_PERIODO,-7))*100 + MONTH(EOMONTH(DT_PERIODO,-7)) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES)
      SET @CD_ANOMES_FIM_180 = (SELECT TOP 1 YEAR(EOMONTH(DT_PERIODO,-1))*100 + MONTH(EOMONTH(DT_PERIODO,-1)) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES)




;WITH MEDIA_180 AS (

              SELECT CD_CLIENTE
                     , AVG(cast(MED_CARTEIRA as decimal(15,2)))  AS MED_CARTEIRA
                FROM ST_CARTEIRA_MEDIA_MENSAL A
               WHERE CD_ANOMES >= @CD_ANOMES_INICIO_180
                 AND CD_ANOMES <= @CD_ANOMES_FIM_180
                   and cd_cliente = CASE WHEN ISNULL(@CD_CLIENTE,'') = ''  THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
            GROUP BY CD_CLIENTE
            )

             ,RELATORIO AS (

                     SELECT A.CD_CLIENTE
                    
                              ,(ISNULL(cast(A.VOLUME_COMPRA as decimal(38,5)) / NULLIF(cast(B.MED_CARTEIRA as decimal(38,5)),0),0) *
                              (cast(@QTD_DIA_UTEIS_ANO as float) / NULLIF(cast(@QTD_DIA_UTEIS_MES as float),0))) AS [TURNOVER_RATIO]
                  
                  , CASE
                                    WHEN (ISNULL(cast(A.VOLUME_COMPRA as decimal(38,5)) / NULLIF(cast(B.MED_CARTEIRA as decimal(38,5)),0),0)
                                    * (cast(@QTD_DIA_UTEIS_ANO as float) / NULLIF(cast(@QTD_DIA_UTEIS_MES as float),0))) < 2
                                    THEN 'NÃO'
                                    WHEN (ISNULL(cast(A.VOLUME_COMPRA as decimal(38,5)) / NULLIF(cast(B.MED_CARTEIRA as decimal(38,5)),0),0)
                                    * (cast(@QTD_DIA_UTEIS_ANO as float) / NULLIF(cast(@QTD_DIA_UTEIS_MES as float),0))) > 8
                                    THEN 'PROVÁVEL' ELSE 'POSSÍVEL' END AS ALERTADO_TR


      ,(ISNULL(ISNULL(CAST(A.CORRETAGEM AS NUMERIC(12,5)),0) /  NULLIF(cast(B.MED_CARTEIRA as decimal(38,5)),0),0)
      * (cast(@QTD_DIA_UTEIS_ANO as float) / NULLIF(cast(@QTD_DIA_UTEIS_MES as float),0)))  AS [COST_EQUITY_RATIO]
      
      ,CASE
                  WHEN (ISNULL(ISNULL(CAST(A.CORRETAGEM AS NUMERIC(15,2)),0) /  NULLIF(cast(B.MED_CARTEIRA as decimal(38,5)),0),0)
                  * (cast(@QTD_DIA_UTEIS_ANO as float) / NULLIF(cast(@QTD_DIA_UTEIS_MES as float),0)))  < 21
                                    THEN 'NÃO'
                                    ELSE 'SIM'
                                    END AS ALERTADO_CE
                              , CORRETAGEM
                              , QTD
                              ,VOLUME_COMPRA
                              ,MED_CARTEIRA
            
                  FROM ST_MESA_AUX_BVSP  A
            LEFT JOIN MEDIA_180 B
                     ON A.CD_CLIENTE = B.CD_CLIENTE     
                  WHERE A.CD_ANOMES = @CD_ANOMES
                  and a.cd_cliente = CASE WHEN ISNULL(@CD_CLIENTE,'') = ''  THEN A.CD_CLIENTE ELSE @CD_CLIENTE END
                  
      )     
        SELECT    CONCAT( @CD_ANO,' / ', @DS_MES) AS PERIODO
                     , A.CD_CLIENTE AS [CÓD. DO CLIENTE]
                     , B.CD_CPFCGC AS [CPF/CNPJ]
                     , B.NM_CLIENTE AS [NOME DO CLIENTE]
                     , cast(TURNOVER_RATIO as decimal(38,5)) AS [TURNOVER RATIO]
                     , ALERTADO_TR AS [ALERTADO TR]
                     , cast(COST_EQUITY_RATIO as decimal(38,5)) AS [COST EQUITY RATIO]
                     , ALERTADO_CE AS [ALERTADO CE]
                     , CORRETAGEM
                     , QTD AS [QUANTIDADE]
                     , format(VOLUME_COMPRA,'f','pt-br') AS [VOL. COMPRA]
                     , MED_CARTEIRA as [MED. CARTEIRA 6M]
                     ,cast(@QTD_DIA_UTEIS_ANO as float) AS [Dias Uteis Semestre]
                     ,cast(@QTD_DIA_UTEIS_MES as float) AS [DIAS UTEIS MES]
                FROM RELATORIO A
         LEFT JOIN V_CLIENTE_TODOS B
                    ON A.CD_CLIENTE = B.CD_CLIENTE

*******************************************************************************************************/