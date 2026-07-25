CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_BMF]
--WITH ENCRYPTION
AS

DECLARE @ERROR_NUMBER INT
	   ,@ERROR_MESSAGE NVARCHAR(MAX)
	   ,@ERROR_LINE INT
	   ,@ERRO VARCHAR(MAX)
	   ,@SUCESSO BIT = 1
	   ,@TIPO INT 
	   ,@IDPROCESSO INT
	   ,@PROCESSO VARCHAR(20)
	   ,@PROCESSO_CARGA VARCHAR(20)
		
	   ---VARIAVEIS DO PROCESSO DE EXECUCÃO DA CARGA
	   ,@PROCESSO_INI  INT
	   ,@PROCESSO_FIM INT
		
	   ---VARIAVEIS PARA CARGA
	   ,@PREGAO SMALLDATETIME
	   ,@PREGAOFIM SMALLDATETIME
	   ,@DT_DEFAULT DATETIME 
	   ,@DIAS_REPROC INT

	   
--teste de gestqao de mudnac
/** COLOCAR A DATA DEFAULT CASO NÃO TENHA DADOS NA TABELA **/
SET @DT_DEFAULT = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'DT_DEFAULT')
SET @DIAS_REPROC = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'REPROCESSAMENTO') 

SET @PROCESSO_CARGA = 'CARGA_BMF'		/** NOME DA CARGA PRINCIAL **/
		
SET @PROCESSO_INI = 1	/** NUMERO DO PROCESSO QUE IRÁ INICIALIZAR 				**/
SET @PROCESSO_FIM = 8	/** NUMERO DO PROCESSO QUE IRÁ FINALIZAR 				**/


---------------------------------------------------------------------------------------------
------------------			COMEÇO DA CARGA			     ------------------------------------
---------------------------------------------------------------------------------------------
PRINT 'CARGA BMF'
EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1, @PROCESSO_CARGA, 9994
BEGIN TRY

	---------------------------------------------------------------------------------------------
	-----------------    FILA DE EXECUCÃO DOS PROCESSOS DE CARGA      ---------------------------
	---------------------------------------------------------------------------------------------
	WHILE @PROCESSO_INI <= @PROCESSO_FIM
	BEGIN
	
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 1)
		BEGIN 
		
			/***********************	
				ST_BMF_NEGOCIOS	
			************************/
			PRINT 'INICIO ST_BMF_NEGOCIOS'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_BMF_NEGOCIOS', 1
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_NEGOCIO) - @DIAS_REPROC AS DATE) FROM ST_BMF_NEGOCIOS), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_BMF_NEGOCIOS] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_BMF_NEGOCIOS'
				  SET @IDPROCESSO	 = 1

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_BMF_NEGOCIOS', 1
			END
			PRINT 'FIM ST_BMF_NEGOCIOS'	
			
		END
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 2)
		BEGIN 
		
			/***********************	
				ST_DIRETAS_BMF	
			************************/
			PRINT 'INICIO ST_DIRETAS_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_DIRETAS_BMF', 2
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_NEGOCIO) - @DIAS_REPROC AS DATE) FROM ST_DIRETAS_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DIRETAS_BMF] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DIRETAS_BMF'
				  SET @IDPROCESSO	 = 2

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_DIRETAS_BMF', 2
			END
			PRINT 'FIM ST_DIRETAS_BMF'	
			
		END
		
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 3)
		BEGIN 
		
			/******************************	
				ST_DAYTRADE_DETALHE_BMF	
			******************************/
			PRINT 'INICIO ST_DAYTRADE_DETALHE_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_DAYTRADE_DETALHE_BMF', 3
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_DATMOV) - @DIAS_REPROC AS DATE) FROM ST_DAYTRADE_DETALHE_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DAYTRADE_DETALHE_BMF] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DAYTRADE_DETALHE_BMF'
				  SET @IDPROCESSO	 = 3

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_DAYTRADE_DETALHE_BMF', 3
			END
			PRINT 'FIM ST_DAYTRADE_DETALHE_BMF'	
			
		END
		
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 4)
		BEGIN 
		
			/******************************	
				ST_DAYTRADE_RESUMO_BMF	
			******************************/
			PRINT 'INICIO ST_DAYTRADE_RESUMO_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_DAYTRADE_RESUMO_BMF', 4
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PREGAO_COMPROU) - @DIAS_REPROC AS DATE) FROM ST_DAYTRADE_RESUMO_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DAYTRADE_RESUMO_BMF]   @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DAYTRADE_RESUMO_BMF'
				  SET @IDPROCESSO	 = 4

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_DAYTRADE_RESUMO_BMF', 4
			END
			PRINT 'FIM ST_DAYTRADE_RESUMO_BMF'	
			
		END
		
		
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 5)
		BEGIN 
		
			/******************************	
				ST_SWINGTRADE_BMF	
			******************************/
			PRINT 'INICIO ST_SWINGTRADE_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_SWINGTRADE_BMF', 5
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(PREGAO) - @DIAS_REPROC AS DATE) FROM ST_SWINGTRADE_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_SWINGTRADE_BMF] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_SWINGTRADE_BMF'
				  SET @IDPROCESSO	 = 5
				  
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_SWINGTRADE_BMF', 5
			END
			PRINT 'FIM ST_SWINGTRADE_BMF'	
			
		END
		
		
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 6)
		BEGIN 
		
			/******************************	
				ST_CONTROLE_VINCULADOS_BMF	
			******************************/
			PRINT 'INICIO ST_CONTROLE_VINCULADOS_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_CONTROLE_VINCULADOS_BMF', 6
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO =  ISNULL((CAST((GETDATE() -5 )  - @DIAS_REPROC  AS DATE)), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_CONTROLE_VINCULADOS_BMF] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CONTROLE_VINCULADOS_BMF'
				  SET @IDPROCESSO	 = 6

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_CONTROLE_VINCULADOS_BMF', 6
			END
			PRINT 'FIM ST_CONTROLE_VINCULADOS_BMF'	
			
		END
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 7)
		BEGIN 
		
			/******************************	
				ST_RESUMO_DIRETAS_BMF	
			******************************/
			PRINT 'INICIO ST_RESUMO_DIRETAS_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_RESUMO_DIRETAS_BMF', 7
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_NEGOCIO) - @DIAS_REPROC AS DATE) FROM ST_RESUMO_DIRETAS_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_RESUMO_DIRETAS_BMF] @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_RESUMO_DIRETAS_BMF'
				  SET @IDPROCESSO	 = 7

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_RESUMO_DIRETAS_BMF', 7
			END
			PRINT 'FIM ST_RESUMO_DIRETAS_BMF'	
			
		END
		
		
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 8)
		BEGIN 
		
			/******************************	
				ST_DAYTRADE_RESUMO_ATIVO_BMF	
			******************************/
			PRINT 'INICIO ST_DAYTRADE_RESUMO_ATIVO_BMF'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_DAYTRADE_RESUMO_ATIVO_BMF', 8
			BEGIN TRANSACTION
				BEGIN TRY
				
					SET @PREGAO = NULL	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PREGAO_COMPROU) - @DIAS_REPROC AS DATE) FROM ST_DAYTRADE_RESUMO_ATIVO_BMF), @DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)	
					
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DAYTRADE_RESUMO_ATIVO_BMF]   @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DAYTRADE_RESUMO_ATIVO_BMF'
				  SET @IDPROCESSO	 = 8

				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_DAYTRADE_RESUMO_ATIVO_BMF', 8
			END
			PRINT 'FIM ST_DAYTRADE_RESUMO_ATIVO_BMF'	
			
		END

		
	-----------------------------------------------------------------------------------------
	------------------		FIM DO LOOP	DOS PROCESSOS		---------------------------------
	-----------------------------------------------------------------------------------------
	SET @PROCESSO_INI = @PROCESSO_INI + 1
	
	END	


---------------------------------------------------------------------------------------------
------------------			FIM DA CARGA			     ------------------------------------
---------------------------------------------------------------------------------------------
END TRY

BEGIN CATCH
		SET @SUCESSO		= 0 
		SET @TIPO 			= 3 
		SET @ERROR_MESSAGE	= ERROR_MESSAGE() 
		SET @PROCESSO 		= @PROCESSO_CARGA
		SET @IDPROCESSO		= 9994

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO  RAISERROR(@ERROR_MESSAGE,16,1)
		
END CATCH

IF(@SUCESSO = 1)
BEGIN

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2, @PROCESSO_CARGA, 9994
END
PRINT 'FIM DA CARGA BMF'