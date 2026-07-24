CREATE PROCEDURE [dbo].[PR_RELATORIO_ALERT_301] @CD_ANO INT, @DS_MES VARCHAR(20), @CD_CLIENTE int, @QTDPORPAGINA INT, @PAGINA INT
--WITH RECOMPILE
AS


--DECLARE @CD_ANO INT, @DS_MES VARCHAR(20), @CD_CLIENTE INT
--SET @CD_ANO = 2025
--SET @DS_MES = 'novembro'
--SET @CD_CLIENTE = ''
 
   

SELECT
 [ANALISE]
,[Referencia]
,[Cód. Cliente]
,[NOME DO CLIENTE]
,[NACIONALIDADE]
,[CPF/CNPJ]
,[PF / PJ]
,[IDADE]
,[INVESTIDOR]
,[DATA DE CRIAÇÃO]
,[FRONTEIRA]
,[PEP SINACOR]
,[PESSOA VINCULADA]
,[INR]
,[ASSESSOR]
,[PROFISSÃO / SEGMENTO DE ATUAÇÃO]
,[PROFISSÃO DE RISCO]
,[SCORE RISCO]
,[RISCO ABR]
,[Money Pass Corretora Bvsp]
,[Money Pass Corretora Bmf]
,[Money Pass Bvsp]
,[Money Pass Bmf]
,[Média Oper. BMF]
,[Média Oper. Bvsp]
,[Transf. Financeira 01]
,[Transf. Financeira 02]
,[Patrimônio X Custódia]
,[Patrimônio X Netting]
,[Patrimônio X Mov Cc]
,[Patrimônio X Transf. Custodia]
,[Atualização Cadastral]
,[Procurador]
,[Mudança Repentina]
,[Ranking Daytrade Bvsp]
,[Ranking Daytrade Bmf]
,[Lista Atenção]
,[Ativo Restrito]
,[Insider Trading]
,[Churning]
,[Omc Bvsp]
,[Omc Bmf]
,[Oscilação]
,[Omg Bvsp]
,[Omg Bmf]
,[Vinculado ao Emissor]
,[TOTAL]
FROM [dbo].[ST_RELATORIO_PAINEL_ALERTAS_CVM]
WHERE LTRIM(LEFT(REFERENCIA, CHARINDEX('/', REFERENCIA) - 1)) = @DS_MES
AND LTRIM(SUBSTRING(REFERENCIA, CHARINDEX('/', REFERENCIA) + 1, LEN(REFERENCIA))) = @CD_ANO
AND [CÓD. CLIENTE] = CASE WHEN ISNULL(@CD_CLIENTE,'')='' THEN [CÓD. CLIENTE] ELSE @CD_CLIENTE END
 



/*

DECLARE @DT date = (SELECT MAX(DT_PERIODO) FROM ST_PERIODO WHERE CD_ANO = @CD_ANO AND DS_MES = @DS_MES);  -- período do pivot (ajuste)
DECLARE @cols        nvarchar(max);
DECLARE @cols_select nvarchar(max);
DECLARE @cols_total  nvarchar(max);
DECLARE @sql         nvarchar(max);

DROP TABLE IF EXISTS STG_WV_RISCO_FINAL
CREATE TABLE STG_WV_RISCO_FINAL ([Data] VARCHAR(20), [Cód. do Cliente] int,[Nome do Cliente] nvarchar(160),[RISCO_FINAL] varchar(5))
INSERT INTO STG_WV_RISCO_FINAL
SELECT [Data],[Cód. do Cliente],[Nome do Cliente],[RISCO_FINAL] 
FROM WV_RISCO_FINAL
where year(data) = @CD_aNO
and CASE WHEN month(data) = 1 THEN 'JANEIRO' 
         WHEN month(data) = 2 THEN 'FEVEREIRO'
         WHEN month(data) = 3 THEN 'MARÇO'
         WHEN month(data) = 4 THEN 'ABRIL'
         WHEN month(data) = 5 THEN 'MAIO'
         WHEN month(data) = 6 THEN 'JUNHO'
         WHEN month(data) = 7 THEN 'JULHO'
         WHEN month(data) = 8 THEN 'AGOSTO'
		 WHEN month(data) = 9 THEN 'SETEMBRO'
         WHEN month(data) = 10 THEN 'OUTUBRO'
         WHEN month(data) = 11 THEN 'NOVEMBRO'
         WHEN month(data) = 12 THEN 'DEZEMBRO' END =  @DS_MES 
and [Cód. do Cliente] =  case when isnull(@cd_cliente,'') = '' then [Cód. do Cliente] else @cd_cliente end


---FRONTEIRA
DROP TABLE IF EXISTS STG_FRONTEIRA
CREATE TABLE STG_FRONTEIRA ([Cidade] varchar(50),[UF] varchar(4))
INSERT INTO STG_FRONTEIRA
SELECT DISTINCT DBO.FN_FORMATAR_TEXTO(NOME)[Cidade],
SUBSTRING(
        Detalhes, 
        CHARINDEX('SIGLA_UF:', Detalhes) + LEN('SIGLA_UF:'), 
        2
    ) AS [UF] FROM ListaAtencao 
WHERE IdSublista = 47
AND  CHARINDEX('SIGLA_UF:', Detalhes) > 0



;WITH A AS (
    SELECT DISTINCT CAST(NM_ALERTA AS nvarchar(4000)) AS NM_ALERTA
    FROM vdash_alertas
    WHERE DT_PERIODO = @DT
	and cd_Cliente =  case when isnull(@cd_cliente,'') = '' then cd_Cliente else @cd_cliente end

)
SELECT
    @cols =
        STUFF((
            SELECT ',' + QUOTENAME(NM_ALERTA)
            FROM A
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, ''),
    @cols_select =
        STUFF((
            SELECT ',format(COALESCE(' + QUOTENAME(NM_ALERTA) + ',0),''0.#'',''pt-br'') AS ' + QUOTENAME(NM_ALERTA)
            FROM A
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, ''),
    @cols_total =
        STUFF((
            SELECT ' + COALESCE(' + QUOTENAME(NM_ALERTA) + ',0)'
            FROM A
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 3, '');

IF @cols IS NULL OR LTRIM(RTRIM(@cols)) = ''
BEGIN
    -- sem alertas no período, retorna só complementares
    SELECT *
    FROM V_CLIENTE_TODOS
	where cd_Cliente =  case when isnull(@cd_cliente,'') = '' then cd_cliente else @cd_cliente end;

    RETURN;
END;

SET @sql = N'
WITH P AS
(
    SELECT
        DT_PERIODO,
        CD_CLIENTE,
        NM_CLIENTE,
        CD_CPFCGC,
        ' + @cols_select + N',
        (' + @cols_total + N') AS TOTAL
    FROM
    (
        SELECT
            DT_PERIODO,
            CD_CLIENTE,
            NM_CLIENTE,
            CD_CPFCGC,
            CAST(NM_ALERTA AS nvarchar(4000)) AS NM_ALERTA,
            1 AS FLAG
        FROM vdash_alertas
        WHERE DT_PERIODO = @Dt
    ) SRC
    PIVOT
    (
        MAX(FLAG) FOR NM_ALERTA IN (' + @cols + N')
    ) PV
)


SELECT
    -- campos complementares
	DISTINCT -- inserido por conta de duplicidade na v_cliente_todos
	CASE
    WHEN UPPER(ISNULL((rsel.RISCO_FINAL), '''')) = ''ALTO''				 THEN ''VERMELHO''
    WHEN UPPER(ISNULL((rsel.RISCO_FINAL), '''')) IN (''MÉDIO'',''MEDIO'') THEN ''AMARELO''
    WHEN UPPER(ISNULL((rsel.RISCO_FINAL), '''')) = ''BAIXO''				 THEN ''VERDE''
    ELSE '''' END AS [ANALISE],
    CASE WHEN MONTH(P.DT_PERIODO) = 1 THEN ''JANEIRO''
         WHEN MONTH(P.DT_PERIODO) = 2 THEN ''FEVEREIRO''
         WHEN MONTH(P.DT_PERIODO) = 3 THEN  ''MARÇO''
         WHEN MONTH(P.DT_PERIODO) = 4 THEN  ''ABRIL''
         WHEN MONTH(P.DT_PERIODO) = 5 THEN  ''MAIO''
         WHEN MONTH(P.DT_PERIODO) = 6 THEN  ''JUNHO''
         WHEN MONTH(P.DT_PERIODO) = 7 THEN  ''JULHO''
         WHEN MONTH(P.DT_PERIODO) = 8 THEN  ''AGOSTO''
         WHEN MONTH(P.DT_PERIODO) = 9 THEN  ''SETEMBRO''
         WHEN MONTH(P.DT_PERIODO) = 10 THEN ''OUTUBRO''
         WHEN MONTH(P.DT_PERIODO) = 11 THEN ''NOVEMBRO''
         WHEN MONTH(P.DT_PERIODO) = 12 THEN ''DEZEMBRO'' END +'' / ''+ CAST(YEAR(P.DT_PERIODO) AS VARCHAR) as [Referencia],
    P.CD_CLIENTE as[Cód. Cliente],
    p.nm_cliente as [NOME DO CLIENTE],
    C.DS_NACION as [NACIONALIDADE],
    C.CPFCNPJ as [CPF/CNPJ],
    C.TIPO as [PF / PJ],
    C.[IDADE],
    C.TP_CLIENTE as [INVESTIDOR],
    C.DT_CRIACAO as [DATA DE CRIAÇÃO],
	CASE WHEN F.CIDADE IS NOT NULL THEN ''SIM''
				ELSE ''NÃO''
				END AS FRONTEIRA,
    C.IN_POLITICO_EXP as [PEP SINACOR],
    C.IN_PESS_VINC as [PESSOA VINCULADA],
    C.[INR],
    C.NM_ASSESSOR as [ASSESSOR],
    C.DS_ATIV as [PROFISSÃO / SEGMENTO DE ATUAÇÃO],
    C.RISCO as [PROFISSÃO DE RISCO],
	ISNULL((rsel.RISCO_FINAL), '''') AS [SCORE RISCO],
	C.PERFIL AS [RISCO ABR],
    -- campos do pivot
    ' + @cols + N',
	P.TOTAL
	
FROM P
LEFT JOIN v_cliente_todos C
    ON C.cd_cliente = P.CD_CLIENTE
OUTER APPLY (
  SELECT TOP (1) w.RISCO_FINAL
  FROM STG_WV_RISCO_FINAL w
  WHERE w.[Cód. do Cliente] = P.CD_CLIENTE
    AND w.[Data] <= EOMONTH(P.DT_PERIODO)
  ORDER BY w.[Data] DESC
) rsel

LEFT JOIN STG_FRONTEIRA F ON F.[Cidade] = C.NM_CIDADE AND F.[UF] = C.SG_ESTADO

 

'
EXEC sys.sp_executesql @sql, N'@DT date', @DT=@DT;
*/