CREATE PROCEDURE [dbo].[PR_ANALISE_MESA_RETAIL_BOVESPA]		
(		
   @INICIO SMALLDATETIME, @FIM SMALLDATETIME,@CD_CLIENTE VARCHAR(10), @CD_PAPEL VARCHAR(10), @QTDPORPAGINA INT, @PAGINA INT		
)		
 
 AS	

--DECLARE  @PAGINA  INT 
--DECLARE @QTDPORPAGINA INT ,
--@CD_CLIENTE VARCHAR(10),  @CD_PAPEL VARCHAR(10),@INICIO SMALLDATETIME,@FIM SMALLDATETIME 
--SET @CD_PAPEL=TRY_CONVERT(INT, NULLIF(@CD_CLIENTE, ''))	
--SET @CD_CLIENTE= NULLIF(@CD_PAPEL, '')	
--SET @INICIO ='20251201'		
--SET @FIM ='20251231'  	
 

 drop table if exists #v_cliente_todos
  SELECT DISTINCT
            CD_CLIENTE,
            NM_CLIENTE,
            TIPO,
            CD_CPFCGC
			into #v_cliente_todos
        FROM V_CLIENTE_TODOS
  
;WITH Base AS (
    SELECT 
        F.DT_NEGOCIO,
        F.CD_CLIENTE,
        --Y.NM_CLIENTE,
        --Y.TIPO,
        --Y.CD_CPFCGC,
        F.NR_SEQORD,
        F.HH_NEGOCIO,
        F.NR_NEGOCIO,
        F.CD_PAPEL,
        F.CD_NATOPE,
        F.TP_MERCADO,
        F.QT_MULTIPLICADOR,
        Preco   = (F.VL_NEGOCIO * F.FT_VALORIZACAO),
        Volume  = CASE WHEN F.CD_NATOPE = 'V' THEN -1.0 ELSE 1.0 END * CONVERT(FLOAT, F.VL_TOTNEG),
        F.VL_CORTOT_ORI,
        COR.CD_CORRET,
        COR.NM_CORRET,
        F.CD_ASSESSOR,
        ASS.NM_ASSESSOR,
        PP.DS_OPERADOR
    FROM ST_CORRETAGEM_ORDEM F
    LEFT JOIN ST_CORRETORA COR ON COR.CD_CORRET   = F.CD_CONTRAPARTE
    LEFT JOIN TSCASSES     ASS ON ASS.CD_ASSESSOR = F.CD_ASSESSOR
    LEFT JOIN ST_OPERADOR  PP  ON PP.CD_OPERADOR  = F.CD_OPERADOR
    WHERE
        F.DT_NEGOCIO >= @INICIO
        AND F.DT_NEGOCIO < DATEADD(DAY, 1, @FIM)    -- evita problemas com horário em smalldatetime/datetime
        AND F.CD_PAPEL = (CASE WHEN ISNULL(@CD_PAPEL,'') = '' THEN F.CD_PAPEL ELSE @CD_PAPEL END )		
		AND F.CD_CLIENTE = (CASE WHEN ISNULL(@CD_CLIENTE,'') = '' THEN F.CD_CLIENTE ELSE CONVERT(INT,@CD_CLIENTE) END ) 
)
SELECT
    -- se você precisa "dd/mm/aaaa" e pt-br, use CONVERT (bem mais leve que FORMAT)
    CONVERT(varchar(10), DT_NEGOCIO, 103) AS [DATA],
    f.CD_CLIENTE        AS [Cod. Cliente],
    NM_CLIENTE        AS [Nome Cliente],
    TIPO	          AS [PF/PJ],
    CD_CPFCGC         AS [CPF/CNPJ],
    NR_SEQORD         AS [Nr Seq Ordem],
    HH_NEGOCIO        AS [Hr do Negocio],
    NR_NEGOCIO        AS [Nr negocio],
    CD_PAPEL          AS [Ativo],
    CD_NATOPE         AS [Operação],
    TP_MERCADO        AS [Mercado],

    -- deixe numérico (melhor); formate na aplicação/relatório
    QT_MULTIPLICADOR  AS [Qtd Negocios],
    Preco             AS [Preço],
    Volume            AS [Volume],
    VL_CORTOT_ORI     AS [Corretagem],

    CD_CORRET         AS [Cod. Contraparte],
    NM_CORRET         AS [Nome Contraparte],
    CD_ASSESSOR       AS [Cod. Assessor],
    NM_ASSESSOR       AS [Nome Assessor],
    DS_OPERADOR       AS [Operador]
FROM Base as f
LEFT JOIN #v_cliente_todos Y ON Y.CD_CLIENTE = F.CD_CLIENTE
ORDER BY DT_NEGOCIO DESC, HH_NEGOCIO

OFFSET (ISNULL(@PAGINA,1) - 1) * CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS
FETCH NEXT CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS ONLY
OPTION (RECOMPILE);