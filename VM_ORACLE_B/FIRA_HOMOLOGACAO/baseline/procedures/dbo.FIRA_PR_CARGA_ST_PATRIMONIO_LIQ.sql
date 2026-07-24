CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_PATRIMONIO_LIQ]
AS

-- 1) cria tabela PADRAO baseada na estrutura atual da destino
DROP TABLE IF EXISTS [dbo].[ST_PATRIMONIO_LIQ_PADRAO]
    CREATE TABLE [dbo].[ST_PATRIMONIO_LIQ_PADRAO] (
    [CD_CPFCGC] varchar(30) NULL,
    [CD_GRUPO] decimal(2,0) NOT NULL,
    [DS_GRUPO] varchar(15) NOT NULL,
    [VAL_BENS] float NULL,
    [DS_BEN] varchar(100) NULL,
    [TIPO] varchar(2) NULL,
    [CD_CLIENTE] int NOT NULL,
    [DATA] smalldatetime NULL,
    [CD_SFPSUBGRUPO] int NULL,
    [VAL_CAPTL_SCIAL] float NULL,
    [VAL_CAPTL_GIRO] float NULL,
    [VAL_RENDA_MENSAL] float NULL,
    [VAL_RENDA_ANUAL] float NULL,
    [VAL_SITU_PATRM] float NULL,
    [VAL_PATRM_LIQ] float NULL,
	[DT_FIRA] DATETIME NULL
);

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_PATRIMONIO_LIQ_PADRAO',
  @schema_name='dbo', @base_table='ST_PATRIMONIO_LIQ',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;

-- 3) corpo original



/************************* OBSERVACAO ***********************************

ANTES DE COMPILAR A NOVA CARGA DEVE-SE DESCOMENTAR O PROCESSO ABAIXO, SERAO
CRIADAS AS NOVAS COLUNAS. 
1- DESCOMENTA, RODA E COMENTA NOVAMENTE]
2- RODAR PARA TESTE, CASO DER ALGUM ERRO, PROVALVELMENTE SÃO COLUNAS FORA
DE ORDEM OU ATE MESMO FALTANDO, DEPENDENDO DA CASA
3- COMPILAR A PROC.

O CÁLCULO DO PATRIMÔNIO CONSIDERA, PRIMEIRAMENTE, OS VALORES DE BENS DECLARADOS. 
NA AUSÊNCIA DE BENS DECLARADOS, O PATRIMÔNIO É DETERMINADO COM BASE NAS COLUNAS VAL_SITU_PATRM OU VAL_PATRM_LIQ.
*************************************************************************/
DELETE FROM ST_PATRIMONIO_LIQ WHERE DATA = CAST(GETDATE()-1 AS DATE)

 SELECT
        x.*,
        has_outro_bem =
            MAX(CASE WHEN LTRIM(RTRIM(x.DS_BEN)) <> 'Patrm Liq' THEN 1 ELSE 0 END)
            OVER (PARTITION BY x.CD_CPFCGC, x.CD_CLIENTE, x.DATA, x.TIPO)
    INTO #PART
    FROM (
        select distinct
        A.CD_CPFCGC AS CD_CPFCGC, 
        C.CD_SFPGRUPO AS CD_GRUPO,
        C.CD_SFPSUBGRUPO,
        D.DS_GRUPO AS DS_GRUPO,
        C.VL_BEN AS VAL_BENS,
        0 AS VAL_CAPTL_SCIAL,
        0 AS VAL_CAPTL_GIRO,
        0 AS VAL_RENDA_ANUAL,
        0 AS VAL_SITU_PATRM,
        0 AS VAL_PATRM_LIQ, 
        C.DS_BEN AS DS_BEN, 
        'PF' AS TIPO,
        B.CD_CLIENTE AS CD_CLIENTE,
        CAST(GETDATE()-1 AS DATE) AS DATA
        FROM TSCCLIGER A
        INNER JOIN TSCCLIBOL B ON A.CD_CPFCGC = B.CD_CPFCGC
        INNER JOIN TSCSFP C ON A.CD_CPFCGC = C.CD_CPFCGC
        INNER JOIN TSCSFPGRUPO D ON C.CD_SFPGRUPO = D.CD_GRUPO
        INNER JOIN TSCSFPSUBGRU E ON C.CD_SFPSUBGRUPO = E.CD_SUBGRUPO AND D.CD_GRUPO = E.CD_GRUPO
        WHERE A.TP_PESSOA = 'F'

        UNION

        select distinct
        A.CD_CPFCGC AS CD_CPFCGC, 
        C.CD_SFPGRUPO AS CD_GRUPO,
        C.CD_SFPSUBGRUPO,
        D.DS_GRUPO AS DS_GRUPO,
        C.VL_BEN AS VAL_BENS,
        0 AS VAL_CAPTL_SCIAL,
        0 AS VAL_CAPTL_GIRO,
        0 AS VAL_RENDA_ANUAL,
        0 AS VAL_SITU_PATRM,
        0 AS VAL_PATRM_LIQ, 
        C.DS_BEN AS DS_BEN, 
        'PJ' AS TIPO,
        B.CD_CLIENTE AS CD_CLIENTE,
        CAST(GETDATE()-1 AS DATE) AS DATA
        FROM TSCCLIGER A
        INNER JOIN TSCCLIBOL B ON A.CD_CPFCGC = B.CD_CPFCGC
        INNER JOIN TSCSFP C ON A.CD_CPFCGC = C.CD_CPFCGC
        INNER JOIN TSCSFPGRUPO D ON C.CD_SFPGRUPO = D.CD_GRUPO
        INNER JOIN TSCSFPSUBGRU E ON C.CD_SFPSUBGRUPO = E.CD_SUBGRUPO AND D.CD_GRUPO = E.CD_GRUPO
        WHERE A.TP_PESSOA = 'J'

        UNION

        select distinct
        A.CD_CPFCGC AS CD_CPFCGC, 
        99 AS CD_GRUPO,
        99 AS CD_SFPSUBGRUPO,
        'PATRM LIQ PF' AS DS_GRUPO,
        0 AS VAL_BENS,
        0 AS VAL_CAPTL_SCIAL,
        0 AS VAL_CAPTL_GIRO,
        isnull(cast(VAL_RENDA_ANUAL as float),0) as  VAL_RENDA_ANUAL,
        isnull(cast(VAL_SITU_PATRM as float),0) as VAL_SITU_PATRM,
        0 AS VAL_PATRM_LIQ, 
        'Patrm Liq' AS DS_BEN, 
        'PF' AS TIPO,
        D.CD_CLIENTE AS CD_CLIENTE,
        CAST(GETDATE()-1 AS DATE) AS DATA
        FROM TSCDXCLI_CLIGER A
        INNER JOIN TSCCLIBOL D ON A.CD_CPFCGC = D.CD_CPFCGC
        INNER JOIN TSCDXPSFI_SFP C ON A.NUM_SEQ_CLIENTE = C.NUM_SEQ_CLIENTE

        UNION

        SELECT DISTINCT
        A.CD_CPFCGC AS CD_CPFCGC, 
        9 AS CD_GRUPO,
        null AS CD_SFPSUBGRUPO,
        'PATRM LIQ PJ' AS DS_GRUPO,
        0 AS VAL_BENS,
        isnull(VAL_CAPTL_SCIAL,0) VAL_CAPTL_SCIAL,
        isnull(VAL_CAPTL_GIRO,0) VAL_CAPTL_GIRO,
        0 AS VAL_RENDA_ANUAL,
        0 AS VAL_SITU_PATRM,
        isnull(VAL_PATRM_LIQ,0) VAL_PATRM_LIQ,
        'Patrm Liq' DS_BEN, 
        'PJ' AS TIPO,
        D.CD_CLIENTE AS CD_CLIENTE,
        CAST(GETDATE()-1 AS DATE) AS DATA
        FROM TSCDXCLI_CLIGER A 
        INNER JOIN TSCCLIBOL D ON A.CD_CPFCGC = D.CD_CPFCGC
        INNER JOIN TSCDXPSJU_SFP C ON A.NUM_SEQ_CLIENTE = C.NUM_SEQ_CLIENTE
    ) x

INSERT INTO ST_PATRIMONIO_LIQ 
(CD_CPFCGC,CD_GRUPO,DS_GRUPO,VAL_BENS,DS_BEN,TIPO,CD_CLIENTE,DATA,VAL_CAPTL_SCIAL,VAL_CAPTL_GIRO,VAL_RENDA_ANUAL,VAL_SITU_PATRM,VAL_PATRM_LIQ,CD_SFPSUBGRUPO,VAL_RENDA_MENSAL)
SELECT
    CD_CPFCGC,
    CD_GRUPO,
    DS_GRUPO,
    SUM(
        CASE
            WHEN LTRIM(RTRIM(DS_BEN)) = 'RENDA MENSAL' THEN 0

            WHEN LTRIM(RTRIM(DS_BEN)) = 'Patrm Liq' AND has_outro_bem = 0 THEN
                CASE
                    WHEN COALESCE(VAL_SITU_PATRM, 0) > 0 AND COALESCE(VAL_PATRM_LIQ, 0) = 0
                        THEN COALESCE(VAL_SITU_PATRM, 0)
                    WHEN COALESCE(VAL_SITU_PATRM, 0) = 0 AND COALESCE(VAL_PATRM_LIQ, 0) > 0
                        THEN COALESCE(VAL_PATRM_LIQ, 0)
                    ELSE 0
                END
            ELSE COALESCE(VAL_BENS, 0)
        END
    ) AS VAL_BENS,

    DS_BEN,
    TIPO,
    CD_CLIENTE,
    DATA,
    SUM(VAL_CAPTL_SCIAL) AS VAL_CAPTL_SCIAL,
    SUM(VAL_CAPTL_GIRO) AS VAL_CAPTL_GIRO,
    SUM(VAL_RENDA_ANUAL) AS VAL_RENDA_ANUAL,
    SUM(VAL_SITU_PATRM) AS VAL_SITU_PATRM,
    SUM(VAL_PATRM_LIQ) AS VAL_PATRM_LIQ,
    CD_SFPSUBGRUPO,
    CASE
        WHEN DS_BEN = 'RENDA MENSAL' THEN SUM(VAL_BENS)
        ELSE CAST(SUM(VAL_RENDA_ANUAL) AS float) / 12
    END AS VAL_RENDA_MENSAL
FROM #PART
--WHERE x.CD_CPFCGC= '219525072' AND CD_CLIENTE = 1
GROUP BY
CD_CPFCGC, CD_GRUPO, CD_SFPSUBGRUPO, DS_GRUPO, DS_BEN, TIPO, CD_CLIENTE, DATA;


-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
	DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_PATRIMONIO_LIQ', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_PATRIMONIO_LIQ]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END


-- 4) limpa PADRAO
DROP TABLE IF EXISTS [dbo].[ST_PATRIMONIO_LIQ_PADRAO];