CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_MONEYPASS_CORRETORA_BMF] @PREGAO SMALLDATETIME, @AUX INT
--WITH ENCRYPTION	
AS

/*
	20/03/2026 - Guimo e Gobbo
		- Atualização do código para ficar igual ao moneypass bmf mas apenas olhando para corretora.

	2026-04-01 - Gobbo e Guimo
		- ajuste na logica da concentração
*/


/*************************************************************************************************
REGRA DO ALERTA:
Resultado >= média do resultado + 3 desvios padrão
intencionalidade >= média da intencionalidade + 3 desvios da intencionalidade
concentração >= média da concentração + 3 desvios da concentração.
*************************************************************************************************/
--passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_MONEYPASS_CORRETORA_BMF_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_MONEYPASS_CORRETORA_BMF_PADRAO](
	DATA DATE,                           
    CD_CLIENTE INT,
	CD_CONTRAPARTE INT,
    NR_NEGOCIOS VARCHAR(MAX),
    PAPEIS VARCHAR(MAX),
	QTD_TOTAL BIGINT,
    RESULTADO DECIMAL(17,3),
    RESULTADO_MEDIA_6M DECIMAL(17,3),
    RESULTADO_DESVIO_6M DECIMAL(17,3),
    CONCENTRACAO DECIMAL(17,3),
    CONCENTRACAO_MEDIA_6M DECIMAL(17,3),
    CONCENTRACAO_DESVIO_6M DECIMAL(17,3),
    IND_ACERTO DECIMAL(17,3),
    IND_ACERTO_MEDIO_6M DECIMAL(17,3),
    IND_ERRO DECIMAL(17,3),
    IND_ERRO_6M DECIMAL(17,3),
    INTENCIONALIDADE DECIMAL(17,3),
    INTENCIONALIDADE_MEDIA_6M DECIMAL(17,3),
    INTENCIONALIDADE_DESVIO_6M DECIMAL(17,3),
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY]
 
 
 
--/***************************************************
--inicio da comparação entre a tabela
--da base padrao fira origem x tabela cliente destino
--*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_MONEYPASS_CORRETORA_BMF_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_MONEYPASS_CORRETORA_BMF',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/

/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20240405'
--SET @AUX = (SELECT DAY(@PREGAO))
 

	DECLARE @INICIO DATE 
		  , @FIM DATE 
		  , @INICIO_6M DATE 
		  , @FIM_6M DATE;
	
	SELECT @INICIO = MIN(DT_PERIODO)
		 , @FIM = MAX(DT_PERIODO)
	  FROM ST_PERIODO
	  WHERE CD_MES = DATEPART(MONTH,DATEADD(DAY,-@AUX , @PREGAO))
	    AND CD_ANO = DATEPART(YEAR,DATEADD(DAY,- @AUX , @PREGAO))

	    SET @INICIO_6M = (SELECT MIN(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANOMES = (SELECT MIN(CD_ANOMES) FROM ST_PERIODO WHERE DT_PERIODO >= DATEADD(MONTH,-6,@INICIO) AND  DT_PERIODO < @INICIO))
		SET @FIM_6M    = (SELECT MAX(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANOMES = (SELECT MAX(CD_ANOMES) FROM ST_PERIODO WHERE DT_PERIODO >= DATEADD(MONTH,-6,@INICIO) AND  DT_PERIODO < @INICIO))

-----------------------------------------------------------------
-----------------------------------------------------------------

/*

	base_util = base |> select(data, cod_cliente, hr_do_negocio, nr_negocio, ativo,
	  operacao, qtd_negocios, preco, volume, cod_contraparte) |> distinct() |> 
	  mutate(data = dmy(data),
			volume = parse_number(volume),
			qtd_negocios = as.integer(gsub("\\.", "", qtd_negocios)),
			preco = as.numeric(gsub("\\,", ".", preco)))

*/


 ---------------------------------------------------------------- MES INICIO
 ---------------------------------------------------------------------------
DROP TABLE IF EXISTS #NC;
;WITH NEGOCIO_AGRUPADO AS
    (
        SELECT
            CODCLI,
            NR_NEGOCIO,
            DT_PREGAO,
            MAX(HR_NEGOCIO)   AS HR_NEGOCIO,
            MAX(CD_OPERADOR) AS CD_OPERADOR
        FROM ST_BMF_NEGOCIOS_TMP1
        GROUP BY CODCLI, NR_NEGOCIO, DT_PREGAO
    )
    SELECT  
        CONVERT(date, A.DT_NEGOCIO)                    AS data,
        A.CD_CLIENTE                                   AS cod_cliente,
        A.NR_NEGOCIO                                   AS nr_negocio,
        NA.HR_NEGOCIO                                  AS hr_do_negocio,
        A.CD_COMMOD                                    AS commodities,
        ISNULL(A.CD_SERIE,'-')                         AS serie,
        A.CD_NATOPE									   AS operacao,
        A.QT_QTDDET                                    AS qtd_negocios,
		CASE 
            WHEN A.CD_NATOPE = 'C' AND A.VL_VALOPE < 0 THEN -A.VL_VALOPE
            WHEN A.CD_NATOPE = 'V' AND A.VL_VALOPE > 0 THEN -A.VL_VALOPE
            ELSE A.VL_VALOPE 
        END            AS preco,
        --CASE 
        --    WHEN A.CD_NATOPE = 'C' AND A.VL_VALOPE < 0 THEN -A.VL_VALOPE
        --    WHEN A.CD_NATOPE = 'V' AND A.VL_VALOPE > 0 THEN -A.VL_VALOPE
        --    ELSE A.VL_VALOPE 
        --END                                            AS volume,
		A.vl_valope AS volume,
        ISNULL(A.CD_CONTRAPARTE,0)                     AS cod_contraparte,
		REPLACE(CONCAT(cd_commod, cd_serie), ' ', '')  AS ativo
		INTO #NC
    FROM ST_BMF_NEGOCIOS_NC A
    LEFT JOIN NEGOCIO_AGRUPADO NA
           ON NA.CODCLI     = A.CD_CLIENTE
          AND NA.NR_NEGOCIO = A.NR_NEGOCIO
          AND NA.DT_PREGAO  = A.DT_NEGOCIO
	
    WHERE
        A.DT_NEGOCIO >= @inicio
    AND A.DT_NEGOCIO <=  @fim
    AND A.TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
	ORDER BY A.DT_NEGOCIO DESC;


 DROP TABLE IF EXISTS #base_util;	 
 SELECT DISTINCT   data
	   , cod_cliente
	   , hr_do_negocio
	   , nr_negocio
	   , ativo --papel
	   , operacao
	   , qtd_negocios
	   , volume / qtd_negocios preco
	   , volume
	   , cod_contraparte 
   INTO  #base_util
   FROM #NC
 
-----------------------------------------------------------------
-----------------------------------------------------------------
	/*
	
	  clientes_compra_venda <- base_util %>%
	  group_by(cod_cliente, cod_contraparte) %>%
	  filter(
		"C" %in% operacao & "V" %in% operacao 
	  ) %>%
	  ungroup()

	*/

DROP TABLE IF EXISTS #pares;
	  SELECT cod_cliente,
	  cod_contraparte
		INTO #pares
		FROM #base_util
	GROUP BY cod_cliente, cod_contraparte
	  HAVING COUNT(CASE WHEN operacao = 'C' THEN 1 END) >= 1
		 AND COUNT(CASE WHEN operacao = 'V' THEN 1 END) >= 1;

 DROP TABLE IF EXISTS #clientes_compra_venda;
		SELECT b.data,    
			   b.cod_cliente,                
			   b.hr_do_negocio,                      
			   b.nr_negocio,                        
			   b.ativo,                               
			   b.operacao,                                 
			   b.qtd_negocios,
			   cast(b.volume as float) / cast(qtd_negocios as float) preco,
			   b.volume,	   
			   b.cod_contraparte  
		  INTO #clientes_compra_venda
		  FROM #base_util AS b
		  JOIN #pares AS p
			ON p.cod_cliente = b.cod_cliente
		   AND p.cod_contraparte = b.cod_contraparte;
	  
-----------------------------------------------------------------
-----------------------------------------------------------------
/*

resultado <- clientes_compra_venda %>%
  group_by(cod_cliente, cod_contraparte, data, operacao) %>%
  summarise(
    numeros_negocio = paste(nr_negocio, collapse = ","),  
    ativos = paste(unique(ativo), collapse = ","),  
    qtd_total = sum(qtd_negocios),                                  
   resultado_total = sum(preco * qtd_negocios),                    
   .groups = "drop"                                       
)

*/

DROP TABLE IF EXISTS #resultado;
DROP TABLE IF EXISTS #base;

    SELECT
    b.cod_cliente,
    b.cod_contraparte,
    b.[data],
    b.operacao,
    b.numeros_negocio,
    b.qtd_total,
    b.resultado_total
INTO #base
FROM (
    SELECT
        c.cod_cliente,
        c.cod_contraparte,
        CAST(c.[data] AS date) AS [data],
        c.operacao,

        numeros_negocio =
            STUFF((
                SELECT ',' + CONVERT(varchar(50), x.nr_negocio)
                FROM #clientes_compra_venda x
                WHERE x.cod_cliente     = c.cod_cliente
                  AND x.cod_contraparte = c.cod_contraparte
                  AND CAST(x.[data] AS date) = CAST(c.[data] AS date)
                  AND x.operacao       = c.operacao
                -- se quiser ordenação, habilite:
                -- ORDER BY x.nr_negocio
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 1, ''),

        SUM(c.qtd_negocios) AS qtd_total,
        SUM(CAST(c.preco AS decimal(18,6)) * CAST(c.qtd_negocios AS decimal(18,0))) AS resultado_total
    FROM #clientes_compra_venda c
    GROUP BY
        c.cod_cliente,
        c.cod_contraparte,
        CAST(c.[data] AS date),
        c.operacao
) b;

SELECT 
    b.cod_cliente,
    b.cod_contraparte,
    b.[data],
    b.operacao,
    b.numeros_negocio,
    STUFF((
        SELECT ',' + a.ativo
        FROM (
            SELECT DISTINCT c2.ativo
            FROM #clientes_compra_venda c2
            WHERE c2.cod_cliente     = b.cod_cliente
              AND c2.cod_contraparte = b.cod_contraparte
              AND CAST(c2.[data] AS date) = b.[data]
              AND c2.operacao       = b.operacao
        ) a
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS ativos,
    b.qtd_total,
    b.resultado_total
INTO #resultado
FROM #base b;

/*

# Passo 1: Criar dados wide (C e V em colunas separadas)
dados_wide <- resultado %>%
  pivot_wider(
    names_from = operacao,
    values_from = resultado_total
  )

*/
DROP TABLE IF EXISTS #dados_wide;

SELECT
    cod_cliente,
    cod_contraparte,
    CAST([data] AS date) AS [data],
    numeros_negocio,             -- mantém como id_col (igual ao R)
    ativos,                      -- mantém como id_col
    qtd_total,                   -- mantém como id_col
    ISNULL([C], 0) AS C,         -- coluna gerada a partir de operacao = 'C'
    ISNULL([V], 0) AS V          -- coluna gerada a partir de operacao = 'V'
INTO #dados_wide
FROM (
    SELECT 
        cod_cliente,
        cod_contraparte,
        CAST([data] AS date) AS [data],
        numeros_negocio,
        ativos,
        qtd_total,
        operacao,
        resultado_total
    FROM #resultado
    -- se quiser reforçar unicidade (deve já ser único por grupo), use DISTINCT:
    -- GROUP BY não é necessário aqui se #resultado já está 1 linha por (cliente, contraparte, data, operacao, numeros_negocio, ativos, qtd_total)
) src
PIVOT (
    SUM(resultado_total) FOR operacao IN ([C], [V])
) p;



/*

# Passo 2: Calcular V - C # Essa tabela serve para termos o resultado
resultado_final = dados_wide %>%
  group_by(cod_cliente, cod_contraparte, data) %>%
  summarise(
    numeros_negocio = paste(unique(unlist(str_split(numeros_negocio, ","))), collapse = ","),  # Junta sem repetir
    ativos = paste(unique(ativos), collapse = ","),  # Junta os ativos (se houver mais de um)
    qtd_total = sum(qtd_total),                     # Soma das quantidades
    C = sum(C, na.rm = TRUE),                       # Soma de "C" (ignorando NA)
    V = sum(V, na.rm = TRUE),                       # Soma de "V" (ignorando NA)
    .groups = "drop"
  ) %>%
  mutate(
    resultado_final = V - C   # Calcula o resultado líquido
  )

*/


--DROP TABLE IF EXISTS #resultado_final;
DROP TABLE IF EXISTS #base_2;

    SELECT
        cod_cliente,
        cod_contraparte,
        CAST([data] AS date) AS [data],
        SUM(ISNULL(qtd_total, 0)) AS qtd_total,
        SUM(ISNULL([C], 0))       AS C,
        SUM(ISNULL([V], 0))       AS V
	into #base_2
    FROM #dados_wide
    GROUP BY cod_cliente, cod_contraparte, CAST([data] AS date)
--),
DROP TABLE IF EXISTS #tokens;
    SELECT
        dw.cod_cliente,
        dw.cod_contraparte,
        CAST(dw.[data] AS date) AS [data],
        LTRIM(RTRIM(s.value))   AS token
    into #tokens
    FROM #dados_wide AS dw
    CROSS APPLY STRING_SPLIT(dw.numeros_negocio, ',') AS s
    WHERE dw.numeros_negocio IS NOT NULL
--),

DROP TABLE IF EXISTS #nums;

SELECT
    g.cod_cliente,
    g.cod_contraparte,
    g.[data],
    numeros_negocio =
        STUFF((
            SELECT ',' + CONVERT(varchar(max), x.token)
            FROM (
                SELECT DISTINCT cod_cliente, cod_contraparte, [data], token
                FROM #tokens
                WHERE token <> ''
            ) x
            WHERE x.cod_cliente     = g.cod_cliente
              AND x.cod_contraparte = g.cod_contraparte
              AND x.[data]          = g.[data]
            -- se quiser ordenar:
            -- ORDER BY x.token
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, '')
INTO #nums
FROM (
    SELECT DISTINCT cod_cliente, cod_contraparte, [data]
    FROM #tokens
    WHERE token <> ''
) g;
--),

DROP TABLE IF EXISTS #ativos_dedup;

SELECT
    g.cod_cliente,
    g.cod_contraparte,
    g.[data],
    ativos =
        STUFF((
            SELECT ',' + CONVERT(varchar(max), x.ativos)
            FROM (
                SELECT DISTINCT
                    cod_cliente,
                    cod_contraparte,
                    CAST([data] AS date) AS [data],
                    ativos
                FROM #dados_wide
                WHERE ativos IS NOT NULL
            ) x
            WHERE x.cod_cliente     = g.cod_cliente
              AND x.cod_contraparte = g.cod_contraparte
              AND x.[data]          = g.[data]
            -- se quiser ordenar:
            -- ORDER BY x.ativos
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, '')
INTO #ativos_dedup
FROM (
    SELECT DISTINCT
        cod_cliente,
        cod_contraparte,
        CAST([data] AS date) AS [data]
    FROM #dados_wide
    WHERE ativos IS NOT NULL
) g;

DROP TABLE IF EXISTS #resultado_final;
SELECT
    b.cod_cliente,
    b.cod_contraparte,
    b.[data],
    ISNULL(n.numeros_negocio, '') AS numeros_negocio,
    ISNULL(a.ativos, '')          AS ativos,
    b.qtd_total,
    b.C,
    b.V,
    (b.V + b.C)                     AS resultado_final
INTO #resultado_final
FROM #base_2 AS b
LEFT JOIN #nums        AS n ON n.cod_cliente = b.cod_cliente
                          AND n.cod_contraparte = b.cod_contraparte
                          AND n.[data] = b.[data]
LEFT JOIN #ativos_dedup AS a ON a.cod_cliente = b.cod_cliente
                           AND a.cod_contraparte = b.cod_contraparte
                           AND a.[data] = b.[data];



/*

# Função auxiliar para limpar e unir valores únicos
limpar_e_unir <- function(x) {
  if (is.list(x)) {
    x <- unlist(x)
  }
  x %>%
    str_split(",") %>%
    unlist() %>%
    unique() %>%
    na.omit() %>%
    sort() %>%
    paste(collapse = ",")
}

# Passo final corrigido
resultado_alerta <- resultado_final %>% 
  group_by(cod_cliente, cod_contraparte) %>%
  summarise(
    numeros_negocios = limpar_e_unir(numeros_negocio),
    ativos = limpar_e_unir(ativos),
    resultado_alerta = sum(resultado_final),
    .groups = "drop"
  )

*/
DROP TABLE IF EXISTS #resultado_alerta;
DROP TABLE IF EXISTS #agg;

    -- Soma do resultado_final por par (igual ao sum no R)
    SELECT
        cod_cliente,
        cod_contraparte,
        SUM(resultado_final) AS resultado_alerta,
		SUM(qtd_total) as qtd_total
    into #agg
	FROM #resultado_final
    GROUP BY cod_cliente, cod_contraparte

--),
-- Quebra os CSVs de numeros_negocio em tokens e limpa espaços/vazios
DROP TABLE IF EXISTS #num_tokens;
    SELECT
        rf.cod_cliente,
        rf.cod_contraparte,
        NULLIF(LTRIM(RTRIM(s.value)), N'') AS token
    into #num_tokens
	FROM #resultado_final rf
    CROSS APPLY STRING_SPLIT(rf.numeros_negocio, N',') s
    WHERE rf.numeros_negocio IS NOT NULL
--),
-- Deduplica os números (equiv. ao unique()+na.omit())
DROP TABLE IF EXISTS #num_dedup;
    SELECT DISTINCT
        cod_cliente, cod_contraparte, token
    into #num_dedup
	FROM #num_tokens
    WHERE token IS NOT NULL
--),
-- Repete o processo para ATIVOS
DROP TABLE IF EXISTS #ativo_tokens;
    SELECT
        rf.cod_cliente,
        rf.cod_contraparte,
        NULLIF(LTRIM(RTRIM(s.value)), N'') AS token
    into #ativo_tokens
	FROM #resultado_final rf
    CROSS APPLY STRING_SPLIT(rf.ativos, N',') s
    WHERE rf.ativos IS NOT NULL
--),
DROP TABLE IF EXISTS #ativo_dedup;
    SELECT DISTINCT
        cod_cliente, cod_contraparte, token
    into #ativo_dedup
	FROM #ativo_tokens
    WHERE token IS NOT NULL
--)
SELECT
    a.cod_cliente,
    a.cod_contraparte,
    ISNULL(STUFF((
        SELECT N',' + nd.token
        FROM #num_dedup nd
        WHERE nd.cod_cliente     = a.cod_cliente
          AND nd.cod_contraparte = a.cod_contraparte
        ORDER BY nd.token                  
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, N''), N'') AS numeros_negocios,
    ISNULL(STUFF((
        SELECT N',' + ad.token
        FROM #ativo_dedup ad
        WHERE ad.cod_cliente     = a.cod_cliente
          AND ad.cod_contraparte = a.cod_contraparte
        ORDER BY ad.token
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, N''), N'') AS ativos,
    a.resultado_alerta,
	a.qtd_total
INTO #resultado_alerta
FROM #agg a;

/*

#_____________________________________________________________________________________________________________________________________________
#Vamos para Concentração!

concentracao = dados_wide %>%
  group_by(cod_cliente, cod_contraparte) %>%
  summarise(
    qtd_total = sum(qtd_total),                     # Soma das quantidades
    C = sum(C, na.rm = TRUE),                       # Soma de "C" (ignorando NA)
    V = sum(V, na.rm = TRUE),                       # Soma de "V" (ignorando NA)
    .groups = "drop"
  ) %>%
  mutate(
    concentracao_contraparte = V + C   # Calcula o resultado líquido
  ) |> select(-C,-V,-qtd_total)

*/
DROP TABLE IF EXISTS #concentracao; 

SELECT
    dw.cod_cliente,
    dw.cod_contraparte,
    --SUM(ISNULL(CAST(dw.V AS decimal(38,10)), 0)) + SUM(ISNULL(CAST(dw.C AS decimal(38,10)), 0)) AS concentracao_contraparte
	sum(abs(preco) * qtd_negocios) AS concentracao_contraparte
INTO #concentracao
FROM #base_util AS dw
GROUP BY dw.cod_cliente, dw.cod_contraparte;


/*

concentracao_total = base_util |> group_by(cod_cliente) |> 
  summarise(concentracao_total = sum(preco * qtd_negocios))

*/
DROP TABLE IF EXISTS #concentracao_total;
SELECT
    cod_cliente,
    CASE
        WHEN SUM(CASE WHEN preco IS NULL OR qtd_negocios IS NULL THEN 1 ELSE 0 END) > 0
             THEN NULL   -- mesmo comportamento do R sem na.rm: se houver NA, o grupo vira NA
        ELSE SUM(CAST(abs(preco) AS decimal(38,10)) * CAST(qtd_negocios AS decimal(38,10)))
    END AS concentracao_total

into #concentracao_total
FROM #base_util
GROUP BY cod_cliente;


/*

concentracao_final = concentracao |> left_join(concentracao_total, by= "cod_cliente") |> 
  mutate(concentracao_final = (concentracao_contraparte/concentracao_total)*100)

*/

DROP TABLE IF EXISTS #concentracao_final;

SELECT
    c.cod_cliente,
    c.cod_contraparte,
    c.concentracao_contraparte,
    t.concentracao_total,
    CAST(
        (CAST(c.concentracao_contraparte AS decimal(38,10))
         / NULLIF(CAST(t.concentracao_total AS decimal(38,10)), 0)) * 100
        AS decimal(38,6)
    ) AS concentracao_final
INTO #concentracao_final
FROM #concentracao AS c
LEFT JOIN #concentracao_total AS t
  ON t.cod_cliente = c.cod_cliente;

/*
#_____________________________________________________________________________________________________________________________________________
#Vamos para Assertividade! ----Guimo vai me matar, mas foi o que eu pensei =/ -----
parear_operacoes <- function(df) {
  df <- df %>% arrange(data)  # Ordena por data
  saldo_c <- tibble(data = as.Date(character()), qtd_negocios = numeric(), preco = numeric())
  saldo_v <- tibble(data = as.Date(character()), qtd_negocios = numeric(), preco = numeric())
  resultados <- list()
  
  for (i in 1:nrow(df)) {
    linha <- df[i, ]
    
    if (linha$operacao == "C") {
      saldo_c <- bind_rows(saldo_c, linha %>% select(data, qtd_negocios, preco))
    } else if (linha$operacao == "V") {
      saldo_v <- bind_rows(saldo_v, linha %>% select(data, qtd_negocios, preco))
    }
    
    # Parear saldos (C vs V)
    while (nrow(saldo_c) > 0 && nrow(saldo_v) > 0) {
      qtd_pareada <- min(saldo_c$qtd_negocios[1], saldo_v$qtd_negocios[1])
      lucro <- qtd_pareada * (saldo_v$preco[1] - saldo_c$preco[1])
      
      resultados[[length(resultados) + 1]] <- tibble(
        cod_cliente = linha$cod_cliente,
        cod_contraparte = linha$cod_contraparte,
        ativo = linha$ativo,
        data_compra = saldo_c$data[1],
        data_venda = saldo_v$data[1],
        qtd_pareada = qtd_pareada,
        lucro = lucro,
        tipo_operacao = "Pareada"
      )
      
      # Atualiza saldos
      saldo_c$qtd_negocios[1] <- saldo_c$qtd_negocios[1] - qtd_pareada
      saldo_v$qtd_negocios[1] <- saldo_v$qtd_negocios[1] - qtd_pareada
      
      if (saldo_c$qtd_negocios[1] == 0) saldo_c <- saldo_c[-1, ]
      if (saldo_v$qtd_negocios[1] == 0) saldo_v <- saldo_v[-1, ]
    }
  }
  
  # Saldos residuais (não pareados)
  saldos_residuais <- bind_rows(
    saldo_c %>% mutate(tipo_residual = "C_residual"),
    saldo_v %>% mutate(tipo_residual = "V_residual")
  )
  
  # Calcula assertividade
  assertividade <-  if (length(resultados) > 0) {
    assertividade <- sum(sapply(resultados, function(x) x$lucro > 0)) / length(resultados)
  } else {
    assertividade <- 0  # Se não houver operações pareadas
  }
  
  # Retorna resultados
  list(
    operacoes_pareadas = bind_rows(resultados),
    saldos_residuais = saldos_residuais,
    assertividade = assertividade
  )
}

# Aplica a todos os grupos (cod_cliente + cod_contraparte + ativo) ----As tres tabelas é para validação. Essa traz a assertividade
assertividade <- clientes_compra_venda %>%
  group_by(cod_cliente, cod_contraparte, ativo) %>%
  group_modify(~ {
    resultado <- parear_operacoes(.x)
    tibble(
      operacoes_pareadas = list(resultado$operacoes_pareadas),
      saldos_residuais = list(resultado$saldos_residuais),
      assertividade = resultado$assertividade
    )
  }) %>%
  ungroup()

# Desaninha as colunas de listas
operacoes_pareadas <- assertividade %>% 
  select(cod_cliente, cod_contraparte, ativo, operacoes_pareadas) %>% 
  tidyr::unnest(operacoes_pareadas)

saldos_residuais <- assertividade %>% 
  select(cod_cliente, cod_contraparte, ativo, saldos_residuais) %>% 
  tidyr::unnest(saldos_residuais)

# Junta tudo (se necessário)
resultado_completo <- bind_rows(
  operacoes_pareadas %>% mutate(tipo = "Pareada"),
  saldos_residuais %>% mutate(tipo = tipo_residual) %>% select(-tipo_residual)
)

#PERCEBI QUE A CONTA DA ASSERTIVIDADE ESTAVA POR ATIVO E QUERIA TRAZER SEM ATIVO.
# 1. Operações pareadas por ativo (já existente no seu código)
op_pareadas <- resultado_completo %>% 
  filter(tipo == "Pareada")

# 2. Assertividade por cliente e contraparte (ignorando ativo)
assertividade_cliente_contraparte <- op_pareadas %>%
  group_by(cod_cliente, cod_contraparte) %>%
  summarise(
    total_operacoes = n(),
    operacoes_positivas = sum(lucro > 0),
    operacoes_negativas = sum(lucro < 0),
    ind_acerto = operacoes_positivas / total_operacoes,
    ind_erro = operacoes_negativas / total_operacoes,
    .groups = "drop"
  )

# 3. Lucro por ativo (já existente)
lucro_por_ativo <- op_pareadas %>%
  group_by(cod_cliente, cod_contraparte, ativo) %>%
  summarise(
    lucro_total = sum(lucro),
    .groups = "drop"
  )

#PERCEBI QUE A ASSERTIVIDADE CONTAVA VARIAS LINHAS DO MESMO DIA, ENTÃO AGRUPEI POR DATA PARA DEPOIS TRAZER A ASSERTIVIDADE.
# 1. Agrupa operações pareadas por dia (considerando mesma data_compra e data_venda)
operacoes_por_dia <- operacoes_pareadas %>%
  group_by(cod_cliente, cod_contraparte, data_compra, data_venda) %>%
  summarise(
    lucro_dia = sum(lucro),  # Soma os lucros das operações do mesmo dia
    .groups = "drop"
  )

# 2. Assertividade por cliente e contraparte (1 linha por dia) _________________ESTA E A ASSERTIVIDADE QUE VAMOS USAR. - POR DATA, CLIENTE E CONTRAPARTE.___________________
assertividade_cliente_contraparte2 <- operacoes_por_dia %>%
  group_by(cod_cliente, cod_contraparte) %>%
  summarise(
    total_dias_pareados = n(),
    operacoes_positivas = sum(lucro_dia > 0),
    operacoes_negativas = sum(lucro_dia < 0),
    ind_acerto = operacoes_positivas / total_dias_pareados,
    ind_erro = operacoes_negativas / total_dias_pareados,
    .groups = "drop"
  )


*/

DROP TABLE IF EXISTS #ops;
SELECT
    id              = IDENTITY(int,1,1),
    CAST(c.data AS datetime2) data,
    cast( c.hr_do_negocio as time(0)) ord_hora,
    cast(c.nr_negocio as bigint) as nr_negocio,
    c.cod_cliente,
    c.cod_contraparte,
    c.ativo,
    c.operacao AS operacao,                       
    CAST(c.qtd_negocios AS decimal(38,6)) as qtd,
    CAST(c.preco        AS decimal(38,6)) as preco
INTO #ops
FROM #clientes_compra_venda AS c;

CREATE INDEX IX_01
ON #ops(cod_cliente, cod_contraparte, ativo, data, ord_hora, nr_negocio, id)
INCLUDE (operacao, qtd, preco);

DROP TABLE IF EXISTS #c;
WITH compras AS (
  SELECT 
      o.*,
      ROW_NUMBER() OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo
                ORDER BY data, ord_hora, nr_negocio, id) as rn_c,
      SUM(qtd) OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo
                ORDER BY data, ord_hora, nr_negocio, id
                ROWS UNBOUNDED PRECEDING) AS cum_c
  FROM #ops o
  WHERE operacao = 'C' AND qtd > 0
)
SELECT 
    id, 
	data, 
	ord_hora, 
	nr_negocio,
    cod_cliente, 
	cod_contraparte, 
	ativo, 
	operacao,
    qtd, 
	preco,
    rn_c, 
	cum_c,
    cum_c - qtd as bstart,
    cum_c as bstop
INTO #c
FROM compras;

CREATE INDEX IX_01
ON #c(cod_cliente, cod_contraparte, ativo, rn_c, data, ord_hora, nr_negocio)
INCLUDE (bstart, bstop, qtd, preco);

DROP TABLE IF EXISTS #v;
;WITH vendas AS (
  SELECT 
      o.*,
        ROW_NUMBER() OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo
                ORDER BY data, ord_hora, nr_negocio, id) AS rn_v,
       SUM(qtd) OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo
                ORDER BY data, ord_hora, nr_negocio, id
                ROWS UNBOUNDED PRECEDING) AS cum_v
  FROM #ops o
  WHERE operacao = 'V' AND qtd > 0
)
SELECT 
    id, 
	data, 
	ord_hora, 
	nr_negocio,
    cod_cliente, 
	cod_contraparte, 
	ativo, 
	operacao,
    qtd, 
	preco,
    rn_v, 
	cum_v,
    cum_v - qtd AS sstart,
    cum_v AS sstop
INTO #v
FROM vendas;

CREATE INDEX IX_01 
ON #v(cod_cliente, cod_contraparte, ativo, rn_v, data, ord_hora, nr_negocio)
INCLUDE (sstart, sstop, qtd, preco);

DROP TABLE IF EXISTS #operacoes_pareadas;
SELECT
    c.cod_cliente,
    c.cod_contraparte,
    c.ativo,
    c.data as data_compra,
    v.data as data_venda,
    CAST(q.qty AS decimal(38,6)) as qtd_pareada,
    c.preco as preco_compra,
    v.preco as preco_venda,
    CAST(q.qty * (v.preco - c.preco) AS decimal(38,6)) as lucro,
    'Pareada'  as tipo_operacao,
    c.rn_c as id_compra,
    v.rn_v as id_venda
INTO #operacoes_pareadas
FROM #c AS c
JOIN #v AS v
  ON  c.cod_cliente     = v.cod_cliente
  AND c.cod_contraparte = v.cod_contraparte
  AND c.ativo           = v.ativo
  AND c.bstart < v.sstop
  AND v.sstart < c.bstop
CROSS APPLY (
    SELECT
         CASE WHEN c.bstart > v.sstart THEN c.bstart ELSE v.sstart END as start_ov,
         CASE WHEN c.bstop  < v.sstop  THEN c.bstop  ELSE v.sstop  END as end_ov
) ov
CROSS APPLY (
    SELECT  
      CASE WHEN ov.end_ov - ov.start_ov > 0
           THEN ov.end_ov - ov.start_ov
           ELSE 0
      END AS qty
) q
WHERE q.qty > 0;

CREATE INDEX IX_01
ON #operacoes_pareadas(cod_cliente, cod_contraparte, ativo, data_compra, data_venda)
INCLUDE (qtd_pareada, lucro, preco_compra, preco_venda, id_compra, id_venda, tipo_operacao);

DROP TABLE IF EXISTS #saldos_residuais;
WITH sum_compra AS (
  SELECT cod_cliente, cod_contraparte, ativo, id_compra, SUM(qtd_pareada) AS qtd_par
  FROM #operacoes_pareadas
  GROUP BY cod_cliente, cod_contraparte, ativo, id_compra
),
sum_venda AS (
  SELECT cod_cliente, cod_contraparte, ativo, id_venda, SUM(qtd_pareada) AS qtd_par
  FROM #operacoes_pareadas
  GROUP BY cod_cliente, cod_contraparte, ativo, id_venda
),
res_c AS (
  SELECT
    c.cod_cliente, 
	c.cod_contraparte, 
	c.ativo,
    c.data as data,
    c.qtd - ISNULL(sc.qtd_par,0) as qtd_residual,
    c.preco as preco,
    'C_residual' as tipo_residual
  FROM #c AS c
  LEFT JOIN sum_compra AS sc
    ON sc.cod_cliente=c.cod_cliente
   AND sc.cod_contraparte=c.cod_contraparte
   AND sc.ativo=c.ativo
   AND sc.id_compra=c.rn_c
  WHERE c.qtd - ISNULL(sc.qtd_par,0) > 0
),
res_v AS (
  SELECT
    v.cod_cliente
	, v.cod_contraparte
	, v.ativo
    , v.data as data
    , v.qtd - ISNULL(sv.qtd_par,0) as qtd_residual
    , v.preco as preco
    , CAST('V_residual' AS varchar(20)) as tipo_residual
  FROM #v AS v
  LEFT JOIN sum_venda AS sv
    ON sv.cod_cliente=v.cod_cliente
   AND sv.cod_contraparte=v.cod_contraparte
   AND sv.ativo=v.ativo
   AND sv.id_venda=v.rn_v
  WHERE v.qtd - ISNULL(sv.qtd_par,0) > 0
)

SELECT
  cod_cliente, cod_contraparte, ativo, data,
  CAST(qtd_residual AS decimal(38,6)) as qtd_negocios,
  preco, tipo_residual
INTO #saldos_residuais
FROM res_c
UNION ALL
SELECT
  cod_cliente, cod_contraparte, ativo, data,
  CAST(qtd_residual AS decimal(38,6)) as qtd_negocios,
  preco, tipo_residual
FROM res_v;

DROP TABLE IF EXISTS #resultado_completo;
SELECT
  op.cod_cliente, op.cod_contraparte, op.ativo,
  op.data_compra, op.data_venda,
  CAST(NULL AS date)          AS data,          
  op.qtd_pareada,
  CAST(NULL AS decimal(38,6)) AS qtd_negocios,  
  op.preco_compra, op.preco_venda,
  CAST(NULL AS decimal(38,6)) AS preco,         
  op.lucro,
  op.tipo_operacao,
  'Pareada' as tipo
INTO #resultado_completo
FROM #operacoes_pareadas op

UNION ALL

SELECT
  sr.cod_cliente, sr.cod_contraparte, sr.ativo,
  CAST(NULL AS datetime2) AS data_compra,
  CAST(NULL AS datetime2) AS data_venda,
  sr.data,
  CAST(NULL AS decimal(38,6)) AS qtd_pareada,
  sr.qtd_negocios,
  CAST(NULL AS decimal(38,6)) AS preco_compra,
  CAST(NULL AS decimal(38,6)) AS preco_venda,
  sr.preco,
  CAST(NULL AS decimal(38,6)) AS lucro,
  CAST(NULL AS varchar(20))   AS tipo_operacao,
  sr.tipo_residual AS tipo
FROM #saldos_residuais sr;


DROP TABLE IF EXISTS #op_pareadas;
SELECT *
INTO #op_pareadas
FROM #resultado_completo
WHERE tipo = 'Pareada';


DROP TABLE IF EXISTS #assertividade_cliente_contraparte;
SELECT
    cod_cliente,
    cod_contraparte,
    COUNT(*) as total_operacoes,
    SUM(CASE WHEN lucro > 0 THEN 1 ELSE 0 END) AS operacoes_positivas,
    SUM(CASE WHEN lucro < 0 THEN 1 ELSE 0 END) AS operacoes_negativas,
    CAST(SUM(CASE WHEN lucro > 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) as ind_acerto,
    CAST(SUM(CASE WHEN lucro < 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_erro
INTO #assertividade_cliente_contraparte
FROM #op_pareadas
GROUP BY cod_cliente, cod_contraparte;

DROP TABLE IF EXISTS #operacoes_por_dia;
SELECT
    cod_cliente,
    cod_contraparte,
    CAST(data_compra AS date)AS data_compra,
    CAST(data_venda  AS date) AS data_venda,
    SUM(lucro) AS lucro_dia
INTO #operacoes_por_dia
FROM #operacoes_pareadas
GROUP BY cod_cliente, cod_contraparte, CAST(data_compra AS date), CAST(data_venda AS date);

DROP TABLE IF EXISTS #assertividade_cliente_contraparte2;
SELECT
    cod_cliente,
    cod_contraparte,
    COUNT(*) AS total_dias_pareados ,
    SUM(CASE WHEN lucro_dia > 0 THEN 1 ELSE 0 END) AS operacoes_positivas,
    SUM(CASE WHEN lucro_dia < 0 THEN 1 ELSE 0 END) AS operacoes_negativas,
    CAST(SUM(CASE WHEN lucro_dia > 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_acerto,
    CAST(SUM(CASE WHEN lucro_dia < 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_erro
INTO #assertividade_cliente_contraparte2
FROM #operacoes_por_dia
GROUP BY cod_cliente, cod_contraparte;

DROP TABLE IF EXISTS #dados_daytrade;
WITH flags AS (
  SELECT
    c.cod_cliente                                       AS cod_cliente,
    c.cod_contraparte                                   AS cod_contraparte,
    c.ativo                                             AS ativo,
    CAST(c.data AS date)                                AS data,
    MAX(CASE WHEN c.operacao = 'C' THEN 1 ELSE 0 END)   AS tem_compra,
    MAX(CASE WHEN c.operacao = 'V' THEN 1 ELSE 0 END)   AS tem_venda
  FROM #clientes_compra_venda AS c
  GROUP BY c.cod_cliente, c.cod_contraparte, c.ativo, CAST(c.data AS date)
)
SELECT
  f.cod_cliente                                         AS cod_cliente,
  f.cod_contraparte                                     AS cod_contraparte,
  f.ativo                                               AS ativo,
  f.data                                                AS data,
  f.tem_compra                                          AS tem_compra,
  f.tem_venda                                           AS tem_venda,
  CASE WHEN f.tem_compra = 1 AND f.tem_venda = 1 THEN 1 ELSE 0 END AS daytrade
INTO #dados_daytrade
FROM flags AS f;

DROP TABLE IF EXISTS #concentracao_daytrade;
SELECT
  d.cod_cliente                                         AS cod_cliente,
  d.cod_contraparte                                     AS cod_contraparte,
  d.ativo                                               AS ativo,
  COUNT(*)                                              AS total_operacoes,
  SUM(CASE WHEN d.daytrade = 1 THEN 1 ELSE 0 END)       AS daytrades,
  CAST(SUM(CASE WHEN d.daytrade = 1 THEN 1 ELSE 0 END) AS decimal(38,6))
    / NULLIF(COUNT(*),0)                                AS proporcao_daytrade
INTO #concentracao_daytrade
FROM #dados_daytrade AS d
GROUP BY d.cod_cliente, d.cod_contraparte, d.ativo;



DROP TABLE IF EXISTS #daytrade_df;
SELECT
  c.cod_cliente                                          AS cod_cliente,
  c.cod_contraparte                                      AS cod_contraparte,
  c.ativo                                                AS ativo,
  CAST(c.data AS date)                                   AS data,
  SUM(CASE WHEN c.operacao = 'C' THEN c.qtd_negocios ELSE 0 END) AS qtd_c,
  SUM(CASE WHEN c.operacao = 'V' THEN c.qtd_negocios ELSE 0 END) AS qtd_v,
  CASE 
    WHEN SUM(CASE WHEN c.operacao = 'C' THEN 1 ELSE 0 END) > 0
     AND SUM(CASE WHEN c.operacao = 'V' THEN 1 ELSE 0 END) > 0
    THEN 1 ELSE 0
  END                                                    AS daytrade
INTO #daytrade_df
FROM #clientes_compra_venda AS c
GROUP BY c.cod_cliente, c.cod_contraparte, c.ativo, CAST(c.data AS date);

DROP TABLE IF EXISTS #prop_daytrade;
WITH dias AS (
  -- total_dias = dias ÚNICOS por par (sem ativo), igual ao n_distinct(data) do R
  SELECT
    cod_cliente,
    cod_contraparte,
    COUNT(DISTINCT data) AS total_dias
  FROM #daytrade_df
  GROUP BY cod_cliente, cod_contraparte
),
daytrades AS (
  SELECT
    cod_cliente,
    cod_contraparte,
    SUM(CAST(daytrade AS int)) AS dias_daytrade
  FROM #daytrade_df
  GROUP BY cod_cliente, cod_contraparte
),
ativos_concat AS (
  SELECT
    t.cod_cliente,
    t.cod_contraparte,
    STUFF((
      SELECT ',' + x.ativo
      FROM (
        SELECT DISTINCT d2.ativo
        FROM #daytrade_df AS d2
        WHERE d2.cod_cliente     = t.cod_cliente
          AND d2.cod_contraparte = t.cod_contraparte
          AND d2.daytrade        = 1
      ) AS x
      ORDER BY x.ativo
      FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'),1,1,'') AS ativos_daytrade
  FROM (
    SELECT DISTINCT cod_cliente, cod_contraparte
    FROM #daytrade_df
    WHERE daytrade = 1
  ) AS t
)
SELECT
  d.cod_cliente,
  d.cod_contraparte,
  d.total_dias,
  dt.dias_daytrade,
  CAST(dt.dias_daytrade AS decimal(38,6)) / NULLIF(d.total_dias, 0) AS proporcao_daytrade,
  ISNULL(a.ativos_daytrade, '') AS ativos_daytrade
INTO #prop_daytrade
FROM dias AS d
JOIN daytrades AS dt
  ON dt.cod_cliente     = d.cod_cliente
 AND dt.cod_contraparte = d.cod_contraparte
LEFT JOIN ativos_concat AS a
  ON a.cod_cliente     = d.cod_cliente
 AND a.cod_contraparte = d.cod_contraparte;


DROP TABLE IF EXISTS #balanceamento_ativo;
SELECT
  d.cod_cliente                                           AS cod_cliente,
  d.cod_contraparte                                       AS cod_contraparte,
  d.ativo                                                 AS ativo,
  AVG(
    CASE 
      WHEN NULLIF(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END, 0) IS NULL
        THEN 0
      ELSE CAST(CASE WHEN d.qtd_c <= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
         / CAST(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
    END
  )                                                       AS balanceamento_ativo
INTO #balanceamento_ativo
FROM #daytrade_df AS d
WHERE d.daytrade = 1
GROUP BY d.cod_cliente, d.cod_contraparte, d.ativo;

DROP TABLE IF EXISTS #balanceamento;
SELECT
    d.cod_cliente,
    d.cod_contraparte,
    AVG(
        CASE 
            WHEN NULLIF(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END, 0) IS NULL
                THEN 0
            ELSE CAST(CASE WHEN d.qtd_c <= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
               / CAST(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
        END
    ) AS balanceamento
INTO #balanceamento
FROM #daytrade_df AS d
WHERE d.daytrade = 1    
GROUP BY d.cod_cliente, d.cod_contraparte;

DROP TABLE IF EXISTS #ativos_union;
SELECT
  u.cod_cliente                                           AS cod_cliente,
  u.cod_contraparte                                       AS cod_contraparte,
  STUFF((
    SELECT ',' + z.ativo
    FROM (
      SELECT DISTINCT a.ativo
      FROM (
        SELECT d.ativo
        FROM #daytrade_df AS d
        WHERE d.cod_cliente = u.cod_cliente
          AND d.cod_contraparte = u.cod_contraparte
          AND d.daytrade = 1
        UNION ALL
        SELECT b.ativo
        FROM #balanceamento_ativo AS b
        WHERE b.cod_cliente = u.cod_cliente
          AND b.cod_contraparte = u.cod_contraparte
      ) AS a
    ) AS z
    ORDER BY z.ativo
    FOR XML PATH(''), TYPE
  ).value('.','nvarchar(max)'),1,1,'')                   AS ativo
INTO #ativos_union
FROM (
  SELECT DISTINCT cod_cliente, cod_contraparte
  FROM (
    SELECT cod_cliente, cod_contraparte FROM #daytrade_df WHERE daytrade = 1
    UNION
    SELECT cod_cliente, cod_contraparte FROM #balanceamento_ativo
  ) AS t
) AS u;

DROP TABLE IF EXISTS #intencao;
SELECT
  p.cod_cliente                                           AS cod_cliente,
  p.cod_contraparte                                       AS cod_contraparte,
  p.proporcao_daytrade                                    AS proporcao_daytrade,
  ISNULL(b.balanceamento, 0)      
  AS balanceamento,
  CAST(p.proporcao_daytrade * ISNULL(b.balanceamento, 0) AS decimal(38,6)) AS score_intencionalidade,
  ISNULL(u.ativo, '')                                     AS ativo
INTO #intencao
FROM #prop_daytrade AS p
LEFT JOIN #balanceamento AS b
  ON b.cod_cliente = p.cod_cliente
 AND b.cod_contraparte = p.cod_contraparte
LEFT JOIN #ativos_union AS u
  ON u.cod_cliente = p.cod_cliente
 AND u.cod_contraparte = p.cod_contraparte;

DROP TABLE IF EXISTS #intencionalidade;
SELECT
  i.cod_cliente                                           AS cod_cliente,
  i.cod_contraparte                                       AS cod_contraparte,
  ISNULL(u.ativo, '')                                     AS ativos,
  MAX(i.score_intencionalidade)                           AS intencionalidade
INTO #intencionalidade
FROM #intencao AS i
LEFT JOIN #ativos_union AS u
  ON u.cod_cliente = i.cod_cliente
 AND u.cod_contraparte = i.cod_contraparte
GROUP BY i.cod_cliente, i.cod_contraparte, u.ativo;


 DROP TABLE IF EXISTS #MoneyPass;
		SELECT
		  ra.cod_cliente                                          AS cod_cliente,
		  ra.cod_contraparte                                      AS cod_contraparte,
		  ra.numeros_negocios                                     AS numeros_negocios,
		  ra.qtd_total											  AS qtd_total,
		  ra.ativos                                               AS ativos, -- do resultado_alerta
		  ra.resultado_alerta                                     AS resultado_alerta,
		  cf.concentracao_final                                   AS concentracao_final,
		  ISNULL(ac2.ind_acerto, 0)                             AS ind_acerto,
		  ISNULL(ac2.ind_erro, 0)                               AS ind_erro,
		  ISNULL(i.intencionalidade, 0)                         AS intencionalidade
		INTO #MoneyPass
		FROM #resultado_alerta AS ra
		INNER JOIN #concentracao_final AS cf
		  ON cf.cod_cliente = ra.cod_cliente
		 AND cf.cod_contraparte = ra.cod_contraparte
		LEFT JOIN #assertividade_cliente_contraparte2 AS ac2
		  ON ac2.cod_cliente = ra.cod_cliente
		 AND ac2.cod_contraparte = ra.cod_contraparte
		INNER JOIN #intencionalidade AS i
		  ON i.cod_cliente = ra.cod_cliente
		 AND i.cod_contraparte = ra.cod_contraparte;


 --------------------------------------------------------------------MES FIM
 ---------------------------------------------------------------------------



 ------------------------------------------------------------6 MESES  INICIO
 ---------------------------------------------------------------------------
 DROP TABLE IF EXISTS #NC_6M;
;WITH NEGOCIO_AGRUPADO_6M AS
    (
        SELECT
            CODCLI,
            NR_NEGOCIO,
            DT_PREGAO,
            MAX(HR_NEGOCIO)   AS HR_NEGOCIO,
            MAX(CD_OPERADOR) AS CD_OPERADOR
        FROM ST_BMF_NEGOCIOS_TMP1
        GROUP BY CODCLI, NR_NEGOCIO, DT_PREGAO
    )
    SELECT  
        CONVERT(date, A.DT_NEGOCIO)                    AS data,
        A.CD_CLIENTE                                   AS cod_cliente,
        A.NR_NEGOCIO                                   AS nr_negocio,
        NA.HR_NEGOCIO                                  AS hr_do_negocio,
        A.CD_COMMOD                                    AS commodities,
        ISNULL(A.CD_SERIE,'-')                         AS serie,
        A.CD_NATOPE									   AS operacao,
        A.QT_QTDDET                                    AS qtd_negocios,
		CASE 
            WHEN A.CD_NATOPE = 'C' AND A.VL_VALOPE < 0 THEN -A.VL_VALOPE
            WHEN A.CD_NATOPE = 'V' AND A.VL_VALOPE > 0 THEN -A.VL_VALOPE
            ELSE A.VL_VALOPE 
        END            AS preco,
        CASE 
            WHEN A.CD_NATOPE = 'C' AND A.VL_VALOPE < 0 THEN -A.VL_VALOPE
            WHEN A.CD_NATOPE = 'V' AND A.VL_VALOPE > 0 THEN -A.VL_VALOPE
            ELSE A.VL_VALOPE 
        END                                            AS volume,
        ISNULL(A.CD_CONTRAPARTE,0)                     AS cod_contraparte,
		REPLACE(CONCAT(cd_commod, cd_serie), ' ', '')  AS ativo

		INTO #NC_6M
    FROM ST_BMF_NEGOCIOS_NC A
    LEFT JOIN NEGOCIO_AGRUPADO_6M NA
           ON NA.CODCLI     = A.CD_CLIENTE
          AND NA.NR_NEGOCIO = A.NR_NEGOCIO
          AND NA.DT_PREGAO  = A.DT_NEGOCIO

    WHERE
        A.DT_NEGOCIO >= @INICIO_6M
    AND A.DT_NEGOCIO <=  @FIM_6M
    AND A.TP_NEGOCIO IN ('NORMAL','DAY TRADE','DAYTRADE')
	ORDER BY A.DT_NEGOCIO DESC;

 DROP TABLE IF EXISTS #base_util_6M;		 
		SELECT DISTINCT  data
			 , cod_cliente
			 , hr_do_negocio
			 , nr_negocio
			 , ativo--papel
			 , operacao
			 , qtd_negocios
			 , volume / qtd_negocios preco
			 , volume
			 , cod_contraparte
			 , CONVERT(CHAR(6),data, 112) AS cd_anomes
		  INTO #base_util_6M 
		  FROM #NC_6M
	
-----------------------------------------------------------------
-----------------------------------------------------------------
DROP TABLE IF EXISTS #pares_6M;
	  SELECT cod_cliente, cod_contraparte , cd_anomes
		INTO #pares_6M
		FROM #base_util_6M
	GROUP BY cod_cliente, cod_contraparte, cd_anomes
	  HAVING COUNT(CASE WHEN operacao = 'C' THEN 1 END) >= 1
		 AND COUNT(CASE WHEN operacao = 'V' THEN 1 END) >= 1;

 DROP TABLE IF EXISTS #clientes_compra_venda_6M;
		SELECT b.data,    
			   b.cod_cliente,                
			   b.hr_do_negocio,                      
			   b.nr_negocio,                        
			   b.ativo,                               
			   b.operacao,                                 
			   b.qtd_negocios,
			   cast(b.volume as float) / cast(qtd_negocios as float) preco,	   
			   b.cod_contraparte ,
			   b.cd_anomes 
		  INTO #clientes_compra_venda_6M
		  FROM #base_util_6M AS b
		  JOIN #pares_6M AS p
			ON p.cod_cliente = b.cod_cliente
		   AND p.cod_contraparte = b.cod_contraparte
		   and p.cd_anomes = b.cd_anomes;
		
-----------------------------------------------------------------
-----------------------------------------------------------------
DROP TABLE IF EXISTS #base_6M;

SELECT
    b.cod_cliente,
    b.cod_contraparte,
    b.cd_anomes,
    b.[data],
    b.operacao,
    b.numeros_negocio,
    b.qtd_total,
    b.resultado_total
INTO #base_6M
FROM (
    SELECT
        c.cod_cliente,
        c.cod_contraparte,
        c.cd_anomes,
        CAST(c.[data] AS date) AS [data],
        c.operacao,

        numeros_negocio =
            STUFF((
                SELECT ',' + CONVERT(varchar(50), x.nr_negocio)
                FROM #clientes_compra_venda_6M x
                WHERE x.cod_cliente     = c.cod_cliente
                  AND x.cod_contraparte = c.cod_contraparte
                  AND x.cd_anomes       = c.cd_anomes
                  AND CAST(x.[data] AS date) = CAST(c.[data] AS date)
                  AND x.operacao        = c.operacao
                -- se quiser ordenar:
                -- ORDER BY x.nr_negocio
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 1, ''),

        SUM(c.qtd_negocios) AS qtd_total,
        SUM(CAST(c.preco AS decimal(18,6)) * CAST(c.qtd_negocios AS decimal(18,0))) AS resultado_total
    FROM #clientes_compra_venda_6M c
    GROUP BY
        c.cod_cliente,
        c.cod_contraparte,
        c.cd_anomes,
        CAST(c.[data] AS date),
        c.operacao
) b;
--)

DROP TABLE IF EXISTS #resultado_6M;  
SELECT 
    b.cod_cliente,
    b.cod_contraparte,
    b.[data],
	b.cd_anomes,
    b.operacao,
    b.numeros_negocio,
    STUFF((
        SELECT ',' + a.ativo
        FROM (
            SELECT DISTINCT c2.ativo
            FROM #clientes_compra_venda_6M c2
            WHERE c2.cod_cliente     = b.cod_cliente
              AND c2.cod_contraparte = b.cod_contraparte
              AND CAST(c2.[data] AS date) = b.[data]
              AND c2.operacao       = b.operacao
			  and c2.cd_anomes = b.cd_anomes
        ) a
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS ativos,
    b.qtd_total,
    b.resultado_total
INTO #resultado_6M
FROM #base_6M b;



DROP TABLE IF EXISTS #dados_wide_6M;

SELECT
    cod_cliente,
    cod_contraparte,
    CAST([data] AS date) AS [data],
	CONVERT(CHAR(6), data, 112) cd_anomes,
    numeros_negocio,             -- mantém como id_col (igual ao R)
    ativos,                      -- mantém como id_col
    qtd_total,                   -- mantém como id_col
    ISNULL([C], 0) AS C,         -- coluna gerada a partir de operacao = 'C'
    ISNULL([V], 0) AS V          -- coluna gerada a partir de operacao = 'V'
INTO #dados_wide_6M
FROM (
    SELECT 
        cod_cliente,
        cod_contraparte,
        CAST([data] AS date) AS [data],
        numeros_negocio,
        ativos,
        qtd_total,
        operacao,
        resultado_total
    FROM #resultado_6M
) src
PIVOT (
    SUM(resultado_total) FOR operacao IN ([C], [V])
) p;


DROP TABLE IF EXISTS #resultado_final_6M; 
WITH base_6M AS (
    SELECT
        cod_cliente,
        cod_contraparte,
        CAST([data] AS date) AS [data],cd_anomes,
        SUM(ISNULL(qtd_total, 0)) AS qtd_total,
        SUM(ISNULL([C], 0))       AS C,
        SUM(ISNULL([V], 0))       AS V
    FROM #dados_wide_6M
    GROUP BY cod_cliente, cod_contraparte, CAST([data] AS date) , cd_anomes
),
tokens_6M AS (
    SELECT
        dw.cod_cliente,
        dw.cod_contraparte,cd_anomes,
        CAST(dw.[data] AS date) AS [data],
        LTRIM(RTRIM(s.value))   AS token
    FROM #dados_wide_6M AS dw
    CROSS APPLY STRING_SPLIT(dw.numeros_negocio, ',') AS s
    WHERE dw.numeros_negocio IS NOT NULL
),
nums_6M AS (
    SELECT
        g.cod_cliente,
        g.cod_contraparte,
        g.[data],
        g.cd_anomes,
        numeros_negocio =
            STUFF((
                SELECT ',' + CONVERT(varchar(max), x.token)
                FROM (
                    SELECT DISTINCT cod_cliente, cod_contraparte, [data], cd_anomes, token
                    FROM tokens_6M
                    WHERE token <> ''
                ) x
                WHERE x.cod_cliente     = g.cod_cliente
                  AND x.cod_contraparte = g.cod_contraparte
                  AND x.[data]          = g.[data]
                  AND x.cd_anomes       = g.cd_anomes
                -- se quiser ordenar:
                -- ORDER BY x.token
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 1, '')
    FROM (
        SELECT DISTINCT cod_cliente, cod_contraparte, [data], cd_anomes
        FROM tokens_6M
        WHERE token <> ''
    ) g

),
ativos_dedup_6M AS (
    SELECT
        g.cod_cliente,
        g.cod_contraparte,
        g.[data],
        g.cd_anomes,
        ativos =
            STUFF((
                SELECT ',' + CONVERT(varchar(max), x.ativos)
                FROM (
                    SELECT DISTINCT
                        cod_cliente,
                        cod_contraparte,
                        CAST([data] AS date) AS [data],
                        cd_anomes,
                        ativos
                    FROM #dados_wide_6M
                    WHERE ativos IS NOT NULL
                ) x
                WHERE x.cod_cliente     = g.cod_cliente
                  AND x.cod_contraparte = g.cod_contraparte
                  AND x.[data]          = g.[data]
                  AND x.cd_anomes       = g.cd_anomes
                -- se quiser ordenar:
                -- ORDER BY x.ativos
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 1, '')
    FROM (
        SELECT DISTINCT
            cod_cliente,
            cod_contraparte,
            CAST([data] AS date) AS [data],
            cd_anomes
        FROM #dados_wide_6M
        WHERE ativos IS NOT NULL
    ) g
)

SELECT
    b.cod_cliente,
    b.cod_contraparte,
	b.cd_anomes,
    ISNULL(n.numeros_negocio, '') AS numeros_negocio,
    ISNULL(a.ativos, '')          AS ativos,
    b.qtd_total,
    b.C,
    b.V,
    (b.V + b.C)                     AS resultado_final
INTO #resultado_final_6M
FROM base_6M AS b
LEFT JOIN nums_6M        AS n ON n.cod_cliente = b.cod_cliente
                          AND n.cod_contraparte = b.cod_contraparte
                          AND n.[data] = b.[data]
						  and n.cd_anomes = b.cd_anomes
LEFT JOIN ativos_dedup_6M AS a ON a.cod_cliente = b.cod_cliente
                           AND a.cod_contraparte = b.cod_contraparte
                           AND a.[data] = b.[data]
						   and a.cd_anomes = b.cd_anomes;


DROP TABLE IF EXISTS #resultado_alerta_6M;
DROP TABLE IF EXISTS #agg_6M;

    -- Soma do resultado_final por par (igual ao sum no R)
    SELECT
        cod_cliente,
        cod_contraparte,
		cd_anomes,
        SUM(resultado_final) AS resultado_alerta
    into #agg_6M
	FROM #resultado_final_6M A
	
GROUP BY cod_cliente
	   , cod_contraparte
	   , cd_anomes 
--),
-- Quebra os CSVs de numeros_negocio em tokens e limpa espaços/vazios
DROP TABLE IF EXISTS #num_tokens_6M;

    SELECT
        rf.cod_cliente,
        rf.cod_contraparte,cd_anomes,
        NULLIF(LTRIM(RTRIM(s.value)), N'') AS token
    into #num_tokens_6M
	FROM #resultado_final_6M rf
    CROSS APPLY STRING_SPLIT(rf.numeros_negocio, N',') s
    WHERE rf.numeros_negocio IS NOT NULL
--),
-- Deduplica os números (equiv. ao unique()+na.omit())
DROP TABLE IF EXISTS #num_dedup_6M;

    SELECT DISTINCT
        cod_cliente, cod_contraparte, token,cd_anomes
    into #num_dedup_6M
	FROM #num_tokens_6M
    WHERE token IS NOT NULL
--),
-- Repete o processo para ATIVOS
DROP TABLE IF EXISTS #ativo_tokens_6M;

    SELECT
        rf.cod_cliente,
        rf.cod_contraparte,cd_anomes,
        NULLIF(LTRIM(RTRIM(s.value)), N'') AS token
    into #ativo_tokens_6M
	FROM #resultado_final_6M rf
    CROSS APPLY STRING_SPLIT(rf.ativos, N',') s
    WHERE rf.ativos IS NOT NULL
--),
DROP TABLE IF EXISTS #ativo_dedup_6M;

    SELECT DISTINCT
        cod_cliente, cod_contraparte, token,cd_anomes
    into #ativo_dedup_6M
	FROM #ativo_tokens_6M
    WHERE token IS NOT NULL
--)
SELECT
    a.cod_cliente,
    a.cod_contraparte,cd_anomes,
    ISNULL(STUFF((
        SELECT N',' + nd.token
        FROM #num_dedup_6M nd
        WHERE nd.cod_cliente     = a.cod_cliente
          AND nd.cod_contraparte = a.cod_contraparte
		  and nd.cd_anomes = a.cd_anomes
        ORDER BY nd.token                  
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, N''), N'') AS numeros_negocios,
    ISNULL(STUFF((
        SELECT N',' + ad.token
        FROM #ativo_dedup_6M ad
        WHERE ad.cod_cliente     = a.cod_cliente
          AND ad.cod_contraparte = a.cod_contraparte
		  and ad.cd_anomes = a.cd_anomes
        ORDER BY ad.token
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, N''), N'') AS ativos,
    a.resultado_alerta
INTO #resultado_alerta_6M
FROM #agg_6M a ;


DROP TABLE IF EXISTS #concentracao_6M;

SELECT
    dw.cod_cliente,
    dw.cod_contraparte,
	dw.cd_anomes,
    --SUM(ISNULL(CAST(dw.V AS decimal(38,10)), 0)) + SUM(ISNULL(CAST(dw.C AS decimal(38,10)), 0)) AS concentracao_contraparte
	sum(abs(preco) * qtd_negocios) AS concentracao_contraparte
INTO #concentracao_6M
FROM #base_util_6M AS dw
	
GROUP BY dw.cod_cliente, dw.cod_contraparte, dw.cd_anomes;



DROP TABLE IF EXISTS #concentracao_total_6M;
SELECT
    cod_cliente, cd_anomes,
    CASE
        WHEN SUM(CASE WHEN preco IS NULL OR qtd_negocios IS NULL THEN 1 ELSE 0 END) > 0
             THEN NULL   -- mesmo comportamento do R sem na.rm: se houver NA, o grupo vira NA
        ELSE SUM(CAST(abs(preco) AS decimal(38,10)) * CAST(qtd_negocios AS decimal(38,10)))
    END AS concentracao_total --gobbo
into #concentracao_total_6M
FROM #base_util_6M A 
	
GROUP BY cod_cliente , cd_anomes;


DROP TABLE IF EXISTS #concentracao_final_6M;

SELECT
    c.cod_cliente,
    c.cod_contraparte,
    c.concentracao_contraparte,
    t.concentracao_total,
	c.cd_anomes,
    CAST(
        (CAST(c.concentracao_contraparte AS decimal(38,10))
         / NULLIF(CAST(t.concentracao_total AS decimal(38,10)), 0)) * 100
        AS decimal(38,6)
    ) AS concentracao_final
INTO #concentracao_final_6M
FROM #concentracao_6M AS c
LEFT JOIN #concentracao_total_6M AS t
  ON t.cod_cliente = c.cod_cliente
and t.cd_anomes = c.cd_anomes;

DROP TABLE IF EXISTS #ops_6M;
SELECT
    id              = IDENTITY(int,1,1),
    CAST(c.data AS datetime2) data,
    cast( c.hr_do_negocio as time(0)) ord_hora,
    cast(c.nr_negocio as bigint) as nr_negocio,
    c.cod_cliente,
    c.cod_contraparte,
    c.ativo,
    c.operacao AS operacao,                       
    CAST(c.qtd_negocios AS decimal(38,6)) as qtd,
    CAST(c.preco        AS decimal(38,6)) as preco,
	cd_anomes
INTO #ops_6M
FROM #clientes_compra_venda_6M AS c;


CREATE INDEX IX_01
ON #ops_6M(cod_cliente, cod_contraparte, ativo, data, ord_hora, nr_negocio, id)
INCLUDE (operacao, qtd, preco);

DROP TABLE IF EXISTS #c_6M;
WITH compras_6M AS (
  SELECT 
      o.*,
      ROW_NUMBER() OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo,cd_anomes
                ORDER BY data, ord_hora, nr_negocio, id) as rn_c,
      SUM(qtd) OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo,cd_anomes
                ORDER BY data, ord_hora, nr_negocio, id
                ROWS UNBOUNDED PRECEDING) AS cum_c
  FROM #ops_6M o
  WHERE operacao = 'C' AND qtd > 0
)
SELECT 
    id, 
	data, 
	CONVERT(CHAR(6), data, 112)cd_anomes,
	ord_hora, 
	nr_negocio,
    cod_cliente, 
	cod_contraparte, 
	ativo, 
	operacao,
    qtd, 
	preco,
    rn_c, 
	cum_c,
    cum_c - qtd as bstart,
    cum_c as bstop
INTO #c_6M
FROM compras_6M;

CREATE INDEX IX_01
ON #c_6M(cod_cliente, cod_contraparte, ativo, rn_c, data, ord_hora, nr_negocio)
INCLUDE (bstart, bstop, qtd, preco);

DROP TABLE IF EXISTS #v_6M;
WITH vendas_6M AS (
  SELECT 
      o.*,
        ROW_NUMBER() OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo,cd_anomes
                ORDER BY data, ord_hora, nr_negocio, id) AS rn_v,
       SUM(qtd) OVER (
                PARTITION BY cod_cliente, cod_contraparte, ativo,cd_anomes
                ORDER BY data, ord_hora, nr_negocio, id
                ROWS UNBOUNDED PRECEDING) AS cum_v
  FROM #ops_6M o
  WHERE operacao = 'V' AND qtd > 0
)
SELECT 
    id, 
	data, 
	CONVERT(CHAR(6), data, 112)cd_anomes,
	ord_hora, 
	nr_negocio,
    cod_cliente, 
	cod_contraparte, 
	ativo, 
	operacao,
    qtd, 
	preco,
    rn_v, 
	cum_v,
    cum_v - qtd AS sstart,
    cum_v AS sstop
INTO #v_6M
FROM vendas_6M;

CREATE INDEX IX_01 
ON #v_6M(cod_cliente, cod_contraparte, ativo, rn_v, data, ord_hora, nr_negocio)
INCLUDE (sstart, sstop, qtd, preco);


DROP TABLE IF EXISTS #operacoes_pareadas_6M;
SELECT
    c.cod_cliente,
    c.cod_contraparte,
    c.ativo,
    c.data as data_compra,
    v.data as data_venda,
    CAST(q.qty AS decimal(38,6)) as qtd_pareada,
    c.preco as preco_compra,
    v.preco as preco_venda,
    CAST(q.qty * (v.preco - c.preco) AS decimal(38,6)) as lucro,
    'Pareada'  as tipo_operacao,
    c.rn_c as id_compra,
    v.rn_v as id_venda,
	c.cd_anomes
INTO #operacoes_pareadas_6M
FROM #c_6M AS c
JOIN #v_6M AS v
  ON  c.cod_cliente     = v.cod_cliente
  AND c.cod_contraparte = v.cod_contraparte
  AND c.ativo           = v.ativo
  and c.cd_anomes		= v.cd_anomes
  AND c.bstart < v.sstop
  AND v.sstart < c.bstop
CROSS APPLY (
    SELECT
         CASE WHEN c.bstart > v.sstart THEN c.bstart ELSE v.sstart END as start_ov,
         CASE WHEN c.bstop  < v.sstop  THEN c.bstop  ELSE v.sstop  END as end_ov
) ov
CROSS APPLY (
    SELECT  
      CASE WHEN ov.end_ov - ov.start_ov > 0
           THEN ov.end_ov - ov.start_ov
           ELSE 0
      END AS qty
) q
WHERE q.qty > 0;

CREATE INDEX IX_01
ON #operacoes_pareadas_6M(cod_cliente, cod_contraparte, ativo, data_compra, data_venda)
INCLUDE (qtd_pareada, lucro, preco_compra, preco_venda, id_compra, id_venda, tipo_operacao);


DROP TABLE IF EXISTS #saldos_residuais_6M;
WITH sum_compra_6M AS (
  SELECT cod_cliente, cod_contraparte, ativo, id_compra,cd_anomes, SUM(qtd_pareada) AS qtd_par
  FROM #operacoes_pareadas_6M
  GROUP BY cod_cliente, cod_contraparte, ativo, id_compra , cd_anomes
),
sum_venda_6M AS (
  SELECT cod_cliente, cod_contraparte, ativo, id_venda,cd_anomes , SUM(qtd_pareada) AS qtd_par
  FROM #operacoes_pareadas_6M
  GROUP BY cod_cliente, cod_contraparte, ativo, id_venda , cd_anomes
),
res_c_6M AS (
  SELECT
    c.cod_cliente, 
	c.cod_contraparte, 
	c.ativo,
    c.data as data,
    c.qtd - ISNULL(sc.qtd_par,0) as qtd_residual,
    c.preco as preco,
    'C_residual' as tipo_residual,
	c.cd_anomes
  FROM #c_6M AS c
  LEFT JOIN sum_compra_6M AS sc
    ON sc.cod_cliente=c.cod_cliente
   AND sc.cod_contraparte=c.cod_contraparte
   AND sc.ativo=c.ativo
   and sc.cd_anomes =c.cd_anomes
   AND sc.id_compra=c.rn_c
  WHERE c.qtd - ISNULL(sc.qtd_par,0) > 0
),
res_v_6M AS (
  SELECT
    v.cod_cliente
	, v.cod_contraparte
	, v.ativo
    , v.data as data
    , v.qtd - ISNULL(sv.qtd_par,0) as qtd_residual
    , v.preco as preco
    , CAST('V_residual' AS varchar(20)) as tipo_residual
	, v.cd_anomes
  FROM #v_6M AS v
  LEFT JOIN sum_venda_6M AS sv
    ON sv.cod_cliente=v.cod_cliente
   AND sv.cod_contraparte=v.cod_contraparte
   and sv.cd_anomes = v.cd_anomes
   AND sv.ativo=v.ativo
   AND sv.id_venda=v.rn_v
  WHERE v.qtd - ISNULL(sv.qtd_par,0) > 0
)

SELECT
  cod_cliente, cod_contraparte, ativo, data, cd_anomes,
  CAST(qtd_residual AS decimal(38,6)) as qtd_negocios,
  preco, tipo_residual
INTO #saldos_residuais_6M
FROM res_c_6M
UNION ALL
SELECT
  cod_cliente, cod_contraparte, ativo, data,cd_anomes,
  CAST(qtd_residual AS decimal(38,6)) as qtd_negocios,
  preco, tipo_residual
FROM res_v_6M;

DROP TABLE IF EXISTS #resultado_completo_6M;
SELECT
  op.cod_cliente, op.cod_contraparte, op.ativo,
  op.data_compra, op.data_venda,
  CAST(NULL AS date)          AS data,          
  op.qtd_pareada,
  CAST(NULL AS decimal(38,6)) AS qtd_negocios,  
  op.preco_compra, op.preco_venda,
  CAST(NULL AS decimal(38,6)) AS preco,         
  op.lucro,
  op.tipo_operacao,
  'Pareada' as tipo , cd_anomes
INTO #resultado_completo_6M
FROM #operacoes_pareadas_6M op

UNION ALL

SELECT
  sr.cod_cliente, sr.cod_contraparte, sr.ativo,
  CAST(NULL AS datetime2) AS data_compra,
  CAST(NULL AS datetime2) AS data_venda,
  sr.data,
  CAST(NULL AS decimal(38,6)) AS qtd_pareada,
  sr.qtd_negocios,
  CAST(NULL AS decimal(38,6)) AS preco_compra,
  CAST(NULL AS decimal(38,6)) AS preco_venda,
  sr.preco,
  CAST(NULL AS decimal(38,6)) AS lucro,
  CAST(NULL AS varchar(20))   AS tipo_operacao,
  sr.tipo_residual AS tipo,cd_anomes
FROM #saldos_residuais_6M sr;


DROP TABLE IF EXISTS #op_pareadas_6M;
SELECT *
INTO #op_pareadas_6M
FROM #resultado_completo_6M
WHERE tipo = 'Pareada';

DROP TABLE IF EXISTS #assertividade_cliente_contraparte_6M;
SELECT
    cod_cliente,
    cod_contraparte,
	cd_anomes,
    COUNT(*) as total_operacoes,
    SUM(CASE WHEN lucro > 0 THEN 1 ELSE 0 END) AS operacoes_positivas,
    SUM(CASE WHEN lucro < 0 THEN 1 ELSE 0 END) AS operacoes_negativas,
    CAST(SUM(CASE WHEN lucro > 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) as ind_acerto,
    CAST(SUM(CASE WHEN lucro < 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_erro
INTO #assertividade_cliente_contraparte_6M
FROM #op_pareadas_6M
GROUP BY cod_cliente, cod_contraparte,cd_anomes;




DROP TABLE IF EXISTS #operacoes_por_dia_6M;
SELECT
    cod_cliente,
    cod_contraparte,
	cd_anomes,
    CAST(data_compra AS date)AS data_compra,
    CAST(data_venda  AS date) AS data_venda,
    SUM(lucro) AS lucro_dia
INTO #operacoes_por_dia_6M
FROM #operacoes_pareadas_6M
GROUP BY cod_cliente, cod_contraparte, CAST(data_compra AS date), CAST(data_venda AS date),cd_anomes;

DROP TABLE IF EXISTS #assertividade_cliente_contraparte2_6M;
SELECT
    cod_cliente,
    cod_contraparte,cd_anomes,
    COUNT(*) AS total_dias_pareados ,
    SUM(CASE WHEN lucro_dia > 0 THEN 1 ELSE 0 END) AS operacoes_positivas,
    SUM(CASE WHEN lucro_dia < 0 THEN 1 ELSE 0 END) AS operacoes_negativas,
    CAST(SUM(CASE WHEN lucro_dia > 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_acerto,
    CAST(SUM(CASE WHEN lucro_dia < 0 THEN 1 ELSE 0 END) AS decimal(18,6))/ NULLIF(COUNT(*),0) AS ind_erro
INTO #assertividade_cliente_contraparte2_6M
FROM #operacoes_por_dia_6M
GROUP BY cod_cliente, cod_contraparte,cd_anomes;

DROP TABLE IF EXISTS #dados_daytrade_6M;
WITH flags_6M AS (
  SELECT
    c.cod_cliente                                       AS cod_cliente,
    c.cod_contraparte                                   AS cod_contraparte,
    c.ativo                                             AS ativo,
	cd_anomes,
    CAST(c.data AS date)                                AS data,
    MAX(CASE WHEN c.operacao = 'C' THEN 1 ELSE 0 END)   AS tem_compra,
    MAX(CASE WHEN c.operacao = 'V' THEN 1 ELSE 0 END)   AS tem_venda
  FROM #clientes_compra_venda_6M AS c
  GROUP BY c.cod_cliente, c.cod_contraparte, c.ativo, CAST(c.data AS date),cd_anomes
)
SELECT
  f.cod_cliente                                         AS cod_cliente,
  f.cod_contraparte                                     AS cod_contraparte,
  f.ativo                                               AS ativo,
  f.data                                                AS data,
  f.tem_compra                                          AS tem_compra,
  f.tem_venda                                           AS tem_venda,
  CASE WHEN f.tem_compra = 1 AND f.tem_venda = 1 THEN 1 ELSE 0 END AS daytrade,
  cd_anomes
INTO #dados_daytrade_6M
FROM flags_6M AS f;

DROP TABLE IF EXISTS #concentracao_daytrade_6M;
SELECT
  d.cod_cliente                                         AS cod_cliente,
  d.cod_contraparte                                     AS cod_contraparte,
  d.ativo                                               AS ativo,
  cd_anomes,
  COUNT(*)                                              AS total_operacoes,
  SUM(CASE WHEN d.daytrade = 1 THEN 1 ELSE 0 END)       AS daytrades,
  CAST(SUM(CASE WHEN d.daytrade = 1 THEN 1 ELSE 0 END) AS decimal(38,6))
    / NULLIF(COUNT(*),0)                                AS proporcao_daytrade
INTO #concentracao_daytrade_6M
FROM #dados_daytrade_6M AS d
GROUP BY d.cod_cliente, d.cod_contraparte, d.ativo,cd_anomes;

DROP TABLE IF EXISTS #daytrade_df_6M;
SELECT
  c.cod_cliente                                          AS cod_cliente,
  c.cod_contraparte                                      AS cod_contraparte,
  c.ativo                                                AS ativo,
  cd_anomes,
  CAST(c.data AS date)                                   AS data,
  SUM(CASE WHEN c.operacao = 'C' THEN c.qtd_negocios ELSE 0 END) AS qtd_c,
  SUM(CASE WHEN c.operacao = 'V' THEN c.qtd_negocios ELSE 0 END) AS qtd_v,
  CASE 
    WHEN SUM(CASE WHEN c.operacao = 'C' THEN 1 ELSE 0 END) > 0
     AND SUM(CASE WHEN c.operacao = 'V' THEN 1 ELSE 0 END) > 0
    THEN 1 ELSE 0
  END                                                    AS daytrade
INTO #daytrade_df_6M
FROM #clientes_compra_venda_6M AS c
GROUP BY c.cod_cliente, c.cod_contraparte, c.ativo, CAST(c.data AS date),cd_anomes;

DROP TABLE IF EXISTS #prop_daytrade_6M;
WITH dias_6M AS (
  -- total_dias = dias ÚNICOS por par (sem ativo), igual ao n_distinct(data) do R
  SELECT
    cod_cliente,
    cod_contraparte,
	cd_anomes,
    COUNT(DISTINCT data) AS total_dias
  FROM #daytrade_df_6M
  GROUP BY cod_cliente, cod_contraparte,cd_anomes
),
daytrades_6M AS (
  SELECT
    cod_cliente,
    cod_contraparte,
    SUM(CAST(daytrade AS int)) AS dias_daytrade
  FROM #daytrade_df_6M
  GROUP BY cod_cliente, cod_contraparte 
),
ativos_concat_6M AS (
  SELECT
    t.cod_cliente,
    t.cod_contraparte,
    STUFF((
      SELECT ',' + x.ativo
      FROM (
        SELECT DISTINCT d2.ativo
        FROM #daytrade_df_6M AS d2
        WHERE d2.cod_cliente     = t.cod_cliente
          AND d2.cod_contraparte = t.cod_contraparte
          AND d2.daytrade        = 1
      ) AS x
      ORDER BY x.ativo
      FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'),1,1,'') AS ativos_daytrade
  FROM (
    SELECT DISTINCT cod_cliente, cod_contraparte
    FROM #daytrade_df_6M
    WHERE daytrade = 1
  ) AS t
)
SELECT
  d.cod_cliente,
  d.cod_contraparte,
  d.cd_anomes,
  d.total_dias,
  dt.dias_daytrade,
  CAST(dt.dias_daytrade AS decimal(38,6)) / NULLIF(d.total_dias, 0) AS proporcao_daytrade,
  ISNULL(a.ativos_daytrade, '') AS ativos_daytrade
  
INTO #prop_daytrade_6M
FROM dias_6M AS d
JOIN daytrades_6M AS dt
  ON dt.cod_cliente     = d.cod_cliente
 AND dt.cod_contraparte = d.cod_contraparte
LEFT JOIN ativos_concat_6M AS a
  ON a.cod_cliente     = d.cod_cliente
 AND a.cod_contraparte = d.cod_contraparte;

DROP TABLE IF EXISTS #balanceamento_ativo_6M;
SELECT
  d.cod_cliente                                           AS cod_cliente,
  d.cod_contraparte                                       AS cod_contraparte,
  d.ativo                                                 AS ativo,
  d.cd_anomes,
  AVG(
    CASE 
      WHEN NULLIF(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END, 0) IS NULL
        THEN 0
      ELSE CAST(CASE WHEN d.qtd_c <= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
         / CAST(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
    END
  )                                                       AS balanceamento_ativo
INTO #balanceamento_ativo_6M
FROM #daytrade_df_6M AS d
WHERE d.daytrade = 1
GROUP BY d.cod_cliente, d.cod_contraparte, d.ativo,d.cd_anomes;


DROP TABLE IF EXISTS #balanceamento_6M;
SELECT
    d.cod_cliente,
    d.cod_contraparte,
	d.cd_anomes,
    AVG(
        CASE 
            WHEN NULLIF(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END, 0) IS NULL
                THEN 0
            ELSE CAST(CASE WHEN d.qtd_c <= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
               / CAST(CASE WHEN d.qtd_c >= d.qtd_v THEN d.qtd_c ELSE d.qtd_v END AS decimal(38,10))
        END
    ) AS balanceamento
INTO #balanceamento_6M
FROM #daytrade_df_6M AS d
WHERE d.daytrade = 1    
GROUP BY d.cod_cliente, d.cod_contraparte , d.cd_anomes ;

DROP TABLE IF EXISTS #ativos_union_6M;
SELECT
  u.cod_cliente                                           AS cod_cliente,
  u.cod_contraparte                                       AS cod_contraparte,
  u.cd_anomes,
  STUFF((
    SELECT ',' + z.ativo
    FROM (
      SELECT DISTINCT a.ativo
      FROM (
        SELECT d.ativo
        FROM #daytrade_df_6M AS d
        WHERE d.cod_cliente = u.cod_cliente
          AND d.cod_contraparte = u.cod_contraparte
		  and d.cd_anomes = u.cd_anomes
          AND d.daytrade = 1
        UNION ALL
        SELECT b.ativo
        FROM #balanceamento_ativo_6M AS b
        WHERE b.cod_cliente = u.cod_cliente
          AND b.cod_contraparte = u.cod_contraparte
		  and b.cd_anomes = u.cd_anomes
      ) AS a
    ) AS z
    ORDER BY z.ativo
    FOR XML PATH(''), TYPE
  ).value('.','nvarchar(max)'),1,1,'')                   AS ativo
INTO #ativos_union_6M
FROM (
  SELECT DISTINCT cod_cliente, cod_contraparte,cd_anomes
  FROM (
    SELECT cod_cliente, cod_contraparte,cd_anomes FROM #daytrade_df_6M WHERE daytrade = 1
    UNION
    SELECT cod_cliente, cod_contraparte,cd_anomes FROM #balanceamento_ativo_6M
  ) AS t
) AS u;


DROP TABLE IF EXISTS #intencao_6M;
SELECT
  p.cod_cliente                                           AS cod_cliente,
  p.cod_contraparte                                       AS cod_contraparte,
  p.cd_anomes,
  p.proporcao_daytrade                                    AS proporcao_daytrade,
  ISNULL(b.balanceamento, 0)                            AS balanceamento,
  CAST(p.proporcao_daytrade * ISNULL(b.balanceamento, 0) AS decimal(38,6)) AS score_intencionalidade,
  ISNULL(u.ativo, '')                                     AS ativo
INTO #intencao_6M
FROM #prop_daytrade_6M AS p
LEFT JOIN #balanceamento_6M AS b
  ON b.cod_cliente = p.cod_cliente
 AND b.cod_contraparte = p.cod_contraparte
 and b.cd_anomes = p.cd_anomes
LEFT JOIN #ativos_union_6M AS u
  ON u.cod_cliente = p.cod_cliente
 AND u.cod_contraparte = p.cod_contraparte
 and u.cd_anomes = p.cd_anomes;

DROP TABLE IF EXISTS #intencionalidade_6M;
SELECT
  i.cod_cliente                                           AS cod_cliente,
  i.cod_contraparte                                       AS cod_contraparte,
  i.cd_anomes,
  ISNULL(u.ativo, '')                                     AS ativos,
  MAX(i.score_intencionalidade)                           AS intencionalidade
INTO #intencionalidade_6M
FROM #intencao_6M AS i
LEFT JOIN #ativos_union_6M AS u
  ON u.cod_cliente = i.cod_cliente
 AND u.cod_contraparte = i.cod_contraparte
 and u.cd_anomes = i.cd_anomes
GROUP BY i.cod_cliente, i.cod_contraparte, u.ativo,i.cd_anomes;

 DROP TABLE IF EXISTS #MoneyPass_6M;
		SELECT
		  ra.cod_cliente                                          AS cod_cliente,
		  ra.cod_contraparte                                      AS cod_contraparte,
		  ra.numeros_negocios                                     AS numeros_negocios,
		  ra.ativos                                               AS ativos, 
		  ra.resultado_alerta                                     AS resultado_alerta,
		  cf.concentracao_final                                   AS concentracao_final,
		  ISNULL(ac2.ind_acerto, 0)                               AS ind_acerto,
		  ISNULL(ac2.ind_erro, 0)                                 AS ind_erro,
		  ISNULL(i.intencionalidade, 0)                           AS intencionalidade,
		  ra.cd_anomes
		INTO #MoneyPass_6M
		FROM #resultado_alerta_6M AS ra
		INNER JOIN #concentracao_final_6M AS cf
		  ON cf.cod_cliente = ra.cod_cliente
		 AND cf.cod_contraparte = ra.cod_contraparte
		 and cf.cd_anomes = ra.cd_anomes
		LEFT JOIN #assertividade_cliente_contraparte2_6M AS ac2
		  ON ac2.cod_cliente = ra.cod_cliente
		 AND ac2.cod_contraparte = ra.cod_contraparte
		 and ac2.cd_anomes = ra.cd_anomes
		INNER JOIN #intencionalidade_6M AS i
		  ON i.cod_cliente = ra.cod_cliente
		 AND i.cod_contraparte = ra.cod_contraparte
		 and i.cd_anomes = ra.cd_anomes;

 -----------------------------------------------------------------6 MESE FIM
 ---------------------------------------------------------------------------
     DROP TABLE IF EXISTS #apenas_pareada; 
		   SELECT 
		 DISTINCT cod_cliente , cod_contraparte , cd_anomes 
		     INTO #apenas_pareada 
		     FROM #op_pareadas_6M

   DROP TABLE IF EXISTS #MoneyPass_6M_metrics_A;
		  SELECT a.cod_cliente
			   , a.cod_contraparte
			   , ISNULL(avg(resultado_alerta)	,0)  AS avg_resultado_alerta
			   , ISNULL(avg(ind_acerto)			,0)  AS avg_ind_acerto
			   , ISNULL(avg(ind_erro)			,0)  AS avg_ind_erro
			   , ISNULL(avg(intencionalidade)	,0)  AS avg_intencionalidade
			   , ISNULL(STDEV(resultado_alerta)  ,0) AS stdev_resultado_alerta

			   , ISNULL(STDEV(ind_acerto)		 ,0) AS stdev_ind_acerto
			   , ISNULL(STDEV(ind_erro)		     ,0) AS stdev_ind_erro
			   , ISNULL(STDEV(intencionalidade)  ,0) AS stdev_intencionalidade
			INTO #MoneyPass_6M_metrics_A
			FROM #MoneyPass_6M  A
			join #apenas_pareada B 
			on a.cod_cliente = b.cod_cliente
			and a.cod_contraparte = b.cod_contraparte
			and a.cd_anomes = b.cd_anomes
		GROUP BY a.cod_cliente
			   , a.cod_contraparte



 DROP TABLE IF EXISTS #MoneyPass_6M_metrics_B;
		  SELECT a.cod_cliente
			   , a.cod_contraparte
			   , ISNULL(avg(concentracao_final) ,0)  AS avg_concentracao_final
			   , ISNULL(STDEV(concentracao_final),0) AS stdev_concentracao_final
			INTO #MoneyPass_6M_metrics_B
			FROM #MoneyPass_6M  A
		GROUP BY a.cod_cliente
			   , a.cod_contraparte;
			   
  DROP TABLE IF EXISTS #MoneyPass_6M_metrics			   
		SELECT A.cod_cliente
			 , A.cod_contraparte
			 , avg_resultado_alerta
			 , avg_concentracao_final
			 , avg_ind_acerto
			 , avg_ind_erro
			 , avg_intencionalidade
			 , stdev_resultado_alerta	
			 , stdev_concentracao_final
			 , stdev_ind_acerto
			 , stdev_ind_erro
			 , stdev_intencionalidade 
		  INTO #MoneyPass_6M_metrics
		  FROM #MoneyPass_6M_metrics_A A
	 LEFT JOIN #MoneyPass_6M_metrics_B B
		    ON A.cod_cliente = B.cod_cliente
		   AND A.cod_contraparte = B.cod_contraparte

    DELETE FROM ST_ALERT_MONEYPASS_CORRETORA_BMF WHERE DATA = CAST(@PREGAO-@AUX AS DATE)            
             
    INSERT INTO ST_ALERT_MONEYPASS_CORRETORA_BMF (DATA,CD_CLIENTE,CD_CONTRAPARTE,NR_NEGOCIOS,PAPEIS,QTD_TOTAL,RESULTADO,RESULTADO_MEDIA_6M,RESULTADO_DESVIO_6M,CONCENTRACAO,CONCENTRACAO_MEDIA_6M,CONCENTRACAO_DESVIO_6M,IND_ACERTO,IND_ACERTO_MEDIO_6M,IND_ERRO,IND_ERRO_6M,INTENCIONALIDADE,INTENCIONALIDADE_MEDIA_6M,INTENCIONALIDADE_DESVIO_6M)         
	 	
		 SELECT 
			    CAST(@PREGAO-@AUX AS DATE)									  AS DATA 
			  , A.cod_cliente												  AS CD_CLIENTE
			  , A.cod_contraparte											  AS CD_CONTRAPARTE
			  , A.numeros_negocios											  AS NR_NEGOCIOS
			  , A.ativos													  AS PAPEIS
			  , A.qtd_total													  AS QTD_TOTAL
			  , ISNULL( CAST(ABS(A.resultado_alerta)	AS DECIMAL(17,3)),0)  AS RESULTADO
			  , ISNULL( CAST(ABS(B.avg_resultado_alerta)AS DECIMAL(17,3)),0)  AS RESULTADO_MEDIA_6M
			  , ISNULL( CAST(B.stdev_resultado_alerta   AS DECIMAL(17,3)),0)  AS RESULTADO_DESVIO_6M		  
			  , ISNULL( CAST(A.concentracao_final	    AS DECIMAL(17,3)),0)  AS CONCENTRACAO
			  , ISNULL( CAST(B.avg_concentracao_final   AS DECIMAL(17,3)),0)  AS CONCENTRACAO_MEDIA_6M
			  , ISNULL( CAST(B.stdev_concentracao_final AS DECIMAL(17,3)),0)  AS CONCENTRACAO_DESVIO_6M
			  , ISNULL( CAST(A.ind_acerto				AS DECIMAL(17,3)),0)  AS IND_ACERTO
			  , ISNULL( CAST(B.avg_ind_acerto			AS DECIMAL(17,3)),0)  AS IND_ACERTO_MEDIO_6M
			  , ISNULL( CAST(A.ind_erro				    AS DECIMAL(17,3)),0)  AS IND_ERRO
			  , ISNULL( CAST(B.avg_ind_erro				AS DECIMAL(17,3)),0)  AS IND_ERRO_6M
			  , ISNULL( CAST(A.intencionalidade			AS DECIMAL(17,3)),0)  AS INTENCIONALIDADE
			  , ISNULL( CAST(B.avg_intencionalidade		AS DECIMAL(17,3)),0)  AS INTENCIONALIDADE_MEDIA_6M
			  , ISNULL( CAST(B.stdev_intencionalidade	AS DECIMAL(17,3)),0)  AS INTENCIONALIDADE_DESVIO_6M
	
		   FROM #MoneyPass A
	  LEFT JOIN #MoneyPass_6M_metrics B
			 ON A.cod_cliente = B.cod_cliente
			AND A.cod_contraparte = B.cod_contraparte
		  WHERE ABS(A.resultado_alerta) > ISNULL(ABS(avg_resultado_alerta)	,0)+(3 * ISNULL(stdev_resultado_alerta  ,0))
			AND A.concentracao_final > ISNULL(avg_concentracao_final,0)+(3 * ISNULL(stdev_concentracao_final,0))
			AND A.intencionalidade   > ISNULL(avg_intencionalidade	,0)+(3 * ISNULL(stdev_intencionalidade  ,0))
			AND A.intencionalidade   > 0 
			AND A.resultado_alerta   > 0
			AND ISNULL( CAST(ABS(B.avg_resultado_alerta)AS DECIMAL(17,3)),0) > 0;

/******* fim do processo de carga do alerta **********/

--passo 3
--/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_MONEYPASS_CORRETORA_BMF_PADRAO