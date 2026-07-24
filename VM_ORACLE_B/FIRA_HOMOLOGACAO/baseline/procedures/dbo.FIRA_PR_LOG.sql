CREATE PROCEDURE [dbo].[FIRA_PR_LOG] @ERROR_NUMBER INT NULL,
								@ERROR_MESSAGE NVARCHAR(MAX) NULL,
								@ERROR_LINE INT NULL,
								@TIPO INT NULL,
								@PROCESSO VARCHAR(MAX)NULL,
								@IDPROCESSO INT NULL


AS

/***
	###	CODIGOS CORRESPONDENTES ###
	
	PROCESSOS PRINCIPAIS
	9991 - CARGA_INCREMENTAL
	9992 - CARGA_CADASTRO
	9993 - CARGA_BOVESPA
	9994 - CARGA_BMF
	
	ALERTAS
	9995 - CARGA_ALERTA_301
	9996 - CARGA_ALERTA_08
	9997 - CARGA ALERTA DIARIO COM ALERTAS DA CORRETORA 
	9998 - CARGA ALERTA CRIPTO
	9999 - CARGA ALERTA BALCAO
***/


DECLARE @ERRO VARCHAR(MAX)

-----------------------------------------------------------------------------------
---					 DIFERENCIAR CARGA E ALERTAS								---
-----------------------------------------------------------------------------------
DECLARE @TABLE_LOG VARCHAR(100),@SQL VARCHAR(MAX)

IF (@PROCESSO LIKE '%ST_ALERT_%' OR @IDPROCESSO = 9995 OR @IDPROCESSO = 9996 OR @IDPROCESSO = 9997 OR @IDPROCESSO = 9998 OR @IDPROCESSO = 9999)
BEGIN
	SET @TABLE_LOG = 'ST_LOG_CARGA_ALERTA'
END
ELSE
BEGIN
	SET @TABLE_LOG = 'ST_LOG_CARGA'
END


-----------------------------------------------------------------------------------
---						IF TIPO 1 -> INSERT NA TABELA DE LOG					---
-----------------------------------------------------------------------------------
IF @TIPO = 1  
BEGIN

	SET @SQL = NULL
	SET @SQL = 'INSERT INTO '+@TABLE_LOG+'(IDPROCESSO, PROCESSO, DTCARGA, DTINICIO) VALUES ('+CAST(@IDPROCESSO AS VARCHAR)+','''+@PROCESSO+''',CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2), CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2))'
	EXEC (@SQL)

END


------------------------------------------------------------------------------------
---						IF TIPO 2 -> INSERT QUANDO FOR SUCESSO                   ---
------------------------------------------------------------------------------------
ELSE IF @TIPO = 2
BEGIN

	---------------------- IMPORTANTE ----------------------------
	--------------------------------------------------------------
	---COLOCAR TODOS OS CÓDIGOS QUE FORAM DAS CARGAS PRINCIPAIS---
	--------------------------------------------------------------
	IF(@IDPROCESSO = 9991 OR @IDPROCESSO = 9992 OR @IDPROCESSO = 9993 OR @IDPROCESSO = 9994 OR @IDPROCESSO = 9995 OR @IDPROCESSO = 9996 OR @IDPROCESSO = 9997 OR @IDPROCESSO = 9998 OR @IDPROCESSO = 9999)
	BEGIN

		SET @SQL = NULL
		SET @SQL ='
			UPDATE '+@TABLE_LOG+'  
			SET DTFIM = CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2),
				STATUS = ''SUCESSO'',
				ERRO = ''N/A''
		
			WHERE 
				IDPROCESSO	= '+CAST(@IDPROCESSO AS VARCHAR)+'
			AND	PROCESSO	= '''+@PROCESSO+'''
			AND DTFIM IS NULL'

		EXEC (@SQL)

	END
	ELSE 
	BEGIN

		---------------------------
		---SUCESSO NOS PROCESSOS---
		---------------------------	   
		SET @SQL = NULL
		SET @SQL ='
			UPDATE '+@TABLE_LOG+' 
			SET DTFIM = CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2),
				STATUS = ''SUCESSO'',
				ERRO = ''N/A''
		
			WHERE 
				IDPROCESSO	= '+CAST(@IDPROCESSO AS VARCHAR)+'
			AND	PROCESSO	= '''+@PROCESSO+'''
			AND DTFIM IS NULL
			'
		EXEC (@SQL)

	END
END


------------------------------------------------------------------------------------
---						IF TIPO 3 -> INDICADOR DE QUANDO HOUVER ERRO             ---
------------------------------------------------------------------------------------
ELSE IF @TIPO = 3
BEGIN

	---------------------- IMPORTANTE ----------------------------
	--------------------------------------------------------------
	---COLOCAR TODOS OS CÓDIGOS QUE FORAM DAS CARGAS PRINCIPAIS---
	--------------------------------------------------------------
	IF(@IDPROCESSO = 9991 OR @IDPROCESSO = 9992 OR @IDPROCESSO = 9993 OR @IDPROCESSO = 9994 OR @IDPROCESSO = 9995 OR @IDPROCESSO = 9996 OR @IDPROCESSO = 9997 OR @IDPROCESSO = 9998 OR @IDPROCESSO = 9999)
	BEGIN

		SET @SQL = NULL
		SET @SQL ='
			UPDATE '+@TABLE_LOG+'  
			SET DTFIM	= CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2),
				STATUS	= ''ERRO'', 
				ERRO	= (SELECT DISTINCT ''PROCESSO: ''+ PROCESSO 
						   FROM(
								SELECT DISTINCT 
									RTRIM(LTRIM(SUBSTRING(ERRO,CHARINDEX('':'',ERRO) + 1, CHARINDEX('' '',ERRO) - 10))) as TABELA,
									PROCESSO,IDPROCESSO
								FROM '+@TABLE_LOG+' 
								WHERE STATUS = ''ERRO'' 
								AND IDPROCESSO NOT IN (9991,9992,9993,9994,9995,9996,9997) 
								)X
							WHERE X.TABELA = '+@TABLE_LOG+'.PROCESSO)
			WHERE 
				IDPROCESSO 	= '+CAST(@IDPROCESSO AS VARCHAR)+'
			AND	PROCESSO 	= '''+@PROCESSO+'''
			AND DTFIM IS NULL'

		EXEC (@SQL)

	END
	ELSE
	BEGIN

		------------------------
		---ERRO DOS PROCESSOS---
		------------------------
		SET @ERRO = 'MENSAGEM:'  + REPLACE(CAST(@ERROR_MESSAGE AS VARCHAR(MAX)),'''','')		   
				  + '  LINHA:'	 + CAST(@ERROR_LINE AS VARCHAR(MAX))
				  + '  NUMERO:'  + CAST(@ERROR_NUMBER AS VARCHAR(MAX))

		SET @SQL = NULL
		SET @SQL ='
			UPDATE '+@TABLE_LOG+'   
			SET DTFIM	= CAST('''+CONVERT(VARCHAR,GETDATE(),25)+''' AS DATETIME2),
				STATUS	= ''ERRO'', 
				ERRO	= '''+@ERRO+'''

			WHERE 
				IDPROCESSO	= '+CAST(@IDPROCESSO AS VARCHAR)+'
			AND	PROCESSO	= '''+@PROCESSO+'''
			AND DTFIM IS NULL'

		EXEC (@SQL)

	END
END