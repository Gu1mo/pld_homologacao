/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_301_LISTA_ATENCAO]    Script Date: 25/02/2026 15:50:21 ******/
CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301_LISTA_ATENCAO] @PREGAO SMALLDATETIME, @AUX INT
AS


/*************************************************************************************************
REGRA DO ALERTA:
Identifica-se os clientes que estão em alguma lista de atenção/restritiva
*************************************************************************************************/

 --passo 1
/**********************************
inicio da etapa de verificação
aqui temos o script da base padrao
***********************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ST_ALERT_LISTA_ATENCAO_PADRAO]') AND type in (N'U'))
CREATE TABLE [dbo].[ST_ALERT_LISTA_ATENCAO_PADRAO](
	[DATA] [date] NULL,
	[CD_CLIENTE] [int] NOT NULL,
	[CD_CPFCGC] [varchar](20) NULL,
	[NM_CLIENTE] [varchar](400) NULL,
	[CPF_PARC] [varchar](1) NOT NULL,
	[CPF_COMP] [varchar](1) NOT NULL,
	[NOME_ENC] [varchar](1) NOT NULL,
	[RSLT_CONS] [nvarchar](max) NULL,
	[DT_FIRA] DATETIME NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo', @src_table='ST_ALERT_LISTA_ATENCAO_PADRAO',
  @schema_name='dbo', @base_table='ST_ALERT_LISTA_ATENCAO',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;
/******** fim da etapa de verificação ************/


/*********inicio da carga do alerta*******/
--DECLARE @PREGAO SMALLDATETIME, @AUX INT
--SET @PREGAO = '20260105'
--SET @AUX = (SELECT DAY(@PREGAO))


 DROP TABLE IF EXISTS #v_Cliente_todos
	SELECT DISTINCT a.CD_CLIENTE,a.nm_Cliente,tp_situac,cd_cpfcgc,IN_SITUAC
	INTO #v_Cliente_todos
	FROM ST_DADOS_BASICOS_PF a
	UNION ALL
	SELECT DISTINCT a.CD_CLIENTE,a.nm_Cliente,TP_situac,cd_cpfcgc,IN_SITUAC
	FROM ST_DADOS_BASICOS_PJ a


		DROP TABLE IF EXISTS #ALERTA_LISTA;
		SELECT 
	    DISTINCT
			  CD_CPFCGC AS CPF_CNPJ
			, CD_CLIENTE
			, NOME
			, TP_SITUAC 
			, IN_SITUAC
			, IDSUBLISTA
			, VERFICACAO
			, CpfCnpj CPF_CNPJ_LISTA
			, NOME_LISTA	
		 INTO #ALERTA_LISTA
		FROM(
			---VERFICACAO: NOME
			SELECT DISTINCT
				CD.CD_CPFCGC,
				CD.CD_CLIENTE,
				LR.NOME,
				TP_SITUAC,
				CASE WHEN IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END IN_SITUAC,
				LR.IDSUBLISTA,
				LR.DETALHES,
				LR.CARGOEXERCIDO,
				'NOME' AS VERFICACAO
				,LR.CpfCnpj
				,LR.Nome NOME_LISTA	
				FROM LISTAATENCAO LR
		  INNER JOIN #v_Cliente_todos CD
				  ON LR.NOME = CD.NM_CLIENTE
			WHERE TP_SITUAC = 'ATIVO'

			UNION ALL

			SELECT DISTINCT
				CD.CD_CPFCGC ,
				CD.CD_CLIENTE,
				LR.NOME ,
				TP_SITUAC,
				CASE WHEN IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END IN_SITUAC,
				LR.IDSUBLISTA,
				LR.DETALHES,
				LR.CARGOEXERCIDO,
				'CPF_PARCIAL' AS VERFICACAO
				,LR.CpfCnpj
				,LR.Nome NOME_LISTA

			FROM LISTAATENCAO LR
			INNER  JOIN #v_Cliente_todos CD
				ON  SUBSTRING(CAST(REPLACE(REPLACE(REPLACE(UPPER(LR.CPFCNPJ),'.',''),'-',''),'/','') AS VARCHAR(30)),4, 6) = SUBSTRING(CAST(REPLACE(REPLACE(REPLACE(CD.CD_CPFCGC,'.',''),'-',''),'/','') AS VARCHAR(30)),4, 6)
				AND UPPER(REPLACE(REPLACE(LR.NOME,'.',''),'/','')) = UPPER(REPLACE(REPLACE(CD.NM_CLIENTE,'.',''),'/',''))
			WHERE  
				(LR.CPFCNPJ IS NOT NULL OR LR.CPFCNPJ <> '')
			AND (SUBSTRING(CAST(LR.CPFCNPJ AS VARCHAR(30)),1, 1) = '*' OR SUBSTRING(CAST(LR.CPFCNPJ AS VARCHAR(30)),1, 1) = 'X')
			AND TP_SITUAC = 'ATIVO'

			UNION ALL

			SELECT DISTINCT 
				CD.CD_CPFCGC,
				CD.CD_CLIENTE,
				LR.NOME ,
				TP_SITUAC,
				CASE WHEN IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END IN_SITUAC,
				LR.IDSUBLISTA,
				LR.DETALHES,
				LR.CARGOEXERCIDO,
				'CPF_COMPLETO' AS VERFICACAO,
				LR.CpfCnpj
				,LR.Nome NOME_LISTA
			FROM LISTAATENCAO LR
			INNER  JOIN #v_Cliente_todos CD
				ON  REPLACE(REPLACE(LR.CPFCNPJ,'.',''),'-','') = REPLACE(REPLACE(CD.CD_CPFCGC,'.',''),'-','')
				AND UPPER(REPLACE(REPLACE(LR.NOME,'.',''),'/','')) = UPPER(REPLACE(REPLACE(CD.NM_CLIENTE,'.',''),'/',''))
			WHERE 
				(LR.CPFCNPJ IS NOT NULL OR LR.CPFCNPJ <> '')
			AND (SUBSTRING(CAST(LR.CPFCNPJ AS VARCHAR(30)),1, 1) <> '*' OR SUBSTRING(CAST(LR.CPFCNPJ AS VARCHAR(30)),1, 1) <> 'X')
			AND TP_SITUAC = 'ATIVO'
		)X
WHERE VERFICACAO ='CPF_PARCIAL'
	


	
	DROP TABLE IF EXISTS #RESULTADO;
	SELECT DISTINCT   
		CPF_CNPJ --AS "CPF / CNPJ",
		,CD_CLIENTE --AS "CÓD. CLIENTE",
		,I.NOME as NM_CLIENTE--AS "NOME DO CLIENTE",
		,TP_SITUAC --AS "SITUAÇÃO CADASTRO GERAL",
		,IN_SITUAC --AS "CADASTRO BOLSA",
		,B.NOME AS LISTA
		 ,case when VERFICACAO = 'CPF_PARCIAL' then 1 else 0 end CPF_PARCIAL
		 ,case when VERFICACAO = 'CPF_COMPLETO' then 1 else 0 end CPF_COMPLETO
		 ,case when VERFICACAO = 'NOME' then 1 else 0 end NOME	
		 ,NOME_LISTA
		 ,CPF_CNPJ_LISTA

	 INTO #RESULTADO
	FROM #ALERTA_LISTA I
	INNER JOIN LISTAATENCAOSUBLISTA B
		ON I.IDSUBLISTA = B.ID
	
	DROP TABLE IF EXISTS #final
	SELECT DATEADD(DAY,-@AUX , @PREGAO) DATA
		 , CD_CLIENTE 		 
		 , CPF_CNPJ CD_CPFCGC
		 , NM_CLIENTE
		 ,CASE WHEN MAX(CPF_PARCIAL)  = 1 THEN 'S'ELSE 'N'END AS CPF_PARC
		 ,CASE WHEN MAX(CPF_COMPLETO) = 1 THEN 'S'ELSE 'N'END AS CPF_COMP
		 ,CASE WHEN MAX(NOME)		  = 1 THEN 'S'ELSE 'N'END AS NOME_ENC
		 ,UPPER(STUFF((SELECT DISTINCT ', ' +' '+LISTA+' | '+CASE WHEN NOME_LISTA IS NULL THEN '' ELSE 'NOME ENCONTRADO:'+ISNULL(NOME_LISTA,'') END + 
		 CASE WHEN CPF_CNPJ_LISTA IS NULL THEN '' ELSE ' CPF ENCONTRADO:'+ISNULL(CPF_CNPJ_LISTA,'') END+' '
              FROM #RESULTADO P
              WHERE P.CD_CLIENTE = #RESULTADO.CD_CLIENTE
              FOR XML PATH('')), 1, 2, '')) AS RSLT_CONS
		into #final
		FROM #RESULTADO
	GROUP BY CD_CLIENTE 
		   , CPF_CNPJ
		   , NM_CLIENTE
		   , TP_SITUAC
		   , IN_SITUAC

	DELETE FROM ST_ALERT_LISTA_ATENCAO WHERE DATA = DATEADD(DAY,-@AUX , @PREGAO); 

	INSERT INTO ST_ALERT_LISTA_ATENCAO
	select * from #final
	where RSLT_CONS not LIKE ('%PESSOAS RELACIONADAS À PEPS%')
	AND  RSLT_CONS not LIKE ('%ATUAÇÃO E EMBARGOS IBAMA%')
    ORDER BY CD_CLIENTE
	
		
/******* fim do processo de carga do alerta **********/
-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_ALERT_LISTA_ATENCAO', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].ST_ALERT_LISTA_ATENCAO
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_ALERT_LISTA_ATENCAO_PADRAO