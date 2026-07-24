CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_CADASTRO]
----WITH ENCRYPTION
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
	   ,@INICIO SMALLDATETIME
	   ,@INICIOFIM SMALLDATETIME
	   ,@DT_DEFAULT DATETIME 
	   ,@DIAS_REPROC INT


/** COLOCAR A DATA DEFAULT CASO NÃO TENHA DADOS NA TABELA **/
SET @DT_DEFAULT = '20220101'	
SET @DIAS_REPROC = 5


SET @PROCESSO_CARGA = 'CARGA_CADASTRO'  /** NOME DA CARGA PRINCIAL **/

SET @PROCESSO_INI = 1	/** NUMERO DO PROCESSO QUE IRÁ INICIALIZAR **/
SET @PROCESSO_FIM = 10	/** NUMERO DO PROCESSO QUE IRÁ FINALIZAR **/

---------------------------------------------------------------------------------------------
------------------			COMEÇO DA CARGA			     ------------------------------------
---------------------------------------------------------------------------------------------
PRINT 'CARGA CADASTRO'
EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1, @PROCESSO_CARGA, 9992
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
			/**********************	
				ST_DADOS_BASICOS_PF
			***********************/
			PRINT 'INICIO ST_DADOS_BASICOS_PF'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_DADOS_BASICOS_PF', 1
			BEGIN TRANSACTION
				BEGIN TRY
				
					--PROCEDURE DE CARGA
					EXEC FIRA_PR_CARGA_ST_DADOS_BASICOS_PF
				 
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO		     = 3 
				  SET @PROCESSO		 = 'ST_DADOS_BASICOS_PF'
				  SET @IDPROCESSO	 = 1

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_DADOS_BASICOS_PF',1
			END
			PRINT 'FIM ST_DADOS_BASICOS_PF'		

		END
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------


		IF  (@PROCESSO_INI = 2)
		BEGIN 
			/**********************	
				ST_DADOS_BASICOS_PJ
			***********************/
			PRINT 'INICIO ST_DADOS_BASICOS_PJ'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_DADOS_BASICOS_PJ', 2
			BEGIN TRANSACTION
				BEGIN TRY
				
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DADOS_BASICOS_PJ]
				
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DADOS_BASICOS_PJ'
				  SET @IDPROCESSO	 = 2

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_DADOS_BASICOS_PJ', 2
			END
			PRINT 'FIM ST_DADOS_BASICOS_PJ'
		
		END
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------


		IF  (@PROCESSO_INI = 3)
		BEGIN 
			/**********************	
				ST_DADOS_FINANCEIROS_PF
			***********************/
			PRINT 'INICIO ST_DADOS_FINANCEIROS_PF'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_DADOS_FINANCEIROS_PF', 3
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DADOS_FINANCEIROS_PF];
				
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DADOS_FINANCEIROS_PF'
				  SET @IDPROCESSO	 = 3

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_DADOS_FINANCEIROS_PF', 3
			END
			PRINT 'FIM ST_DADOS_FINANCEIROS_PF'

		END
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------


		IF  (@PROCESSO_INI = 4)
		BEGIN 
			/**********************	
				ST_DADOS_FINANCEIROS_PJ
			***********************/
			PRINT 'INICIO ST_DADOS_FINANCEIROS_PJ'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_DADOS_FINANCEIROS_PJ', 4
			BEGIN TRANSACTION
				BEGIN TRY
				
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_DADOS_FINANCEIROS_PJ];
				
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DADOS_FINANCEIROS_PJ'
				  SET @IDPROCESSO	 = 4

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_DADOS_FINANCEIROS_PJ', 4
			END
			PRINT 'FIM ST_DADOS_FINANCEIROS_PJ'		
		
		END
		
			
	---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 5)
		BEGIN 
			/**********************	
				ST_PATRIMONIO_LIQ
			***********************/
			PRINT 'INICIO ST_PATRIMONIO_LIQ'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_PATRIMONIO_LIQ', 5
			BEGIN TRANSACTION
				BEGIN TRY
					
					SET @INICIO = NULL	
					SET @INICIO = ISNULL((SELECT CAST(MAX(DATA) AS DATETIME) - @DIAS_REPROC FROM ST_PATRIMONIO_LIQ), @DT_DEFAULT)
					SET @INICIOFIM = NULL
					SET @INICIOFIM = CAST(GETDATE() AS DATE)	
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_PATRIMONIO_LIQ]  		
					
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_PATRIMONIO_LIQ'
				  SET @IDPROCESSO	 = 5

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_PATRIMONIO_LIQ', 5
			END
			PRINT 'FIM ST_PATRIMONIO_LIQ'		
		
		END

			
	---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
	
		IF  (@PROCESSO_INI = 6)
		BEGIN 
			/**********************	
				ST_PATRIMONIO_CUSTODIA
			***********************/
			PRINT 'INICIO ST_PATRIMONIO_CUSTODIA'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_PATRIMONIO_CUSTODIA', 6
			BEGIN TRANSACTION
				BEGIN TRY
					
					SET @INICIO = NULL	
					SET @INICIO = ISNULL((SELECT CAST(MAX(DT_CUSTODIA) AS DATETIME) - @DIAS_REPROC FROM ST_PATRIMONIO_CUSTODIA), @DT_DEFAULT)
					SET @INICIOFIM = NULL
					SET @INICIOFIM = CAST(GETDATE() AS DATE)	
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_PATRIMONIO_CUSTODIA] @INICIO, @INICIOFIM				
					
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_PATRIMONIO_CUSTODIA'
				  SET @IDPROCESSO	 = 6

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_PATRIMONIO_CUSTODIA', 6
			END
			PRINT 'FIM ST_PATRIMONIO_CUSTODIA'		
		
		END

		---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
		
		IF  (@PROCESSO_INI =7)
		BEGIN 
			/**********************	
				ST_PATRIMONIO_MOVCC_FINAL
			***********************/
			PRINT 'INICIO ST_PATRIMONIO_MOVCC_FINAL'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_PATRIMONIO_MOVCC_FINAL', 7
			BEGIN TRANSACTION
				BEGIN TRY
					
					SET @INICIO = NULL	
					SET @INICIO = ISNULL((SELECT CAST(MAX(DT_REFERENCIA) AS DATETIME) - @DIAS_REPROC FROM ST_PATRIMONIO_MOVCC_FINAL), @DT_DEFAULT)
					SET @INICIOFIM = NULL
					SET @INICIOFIM = CAST(GETDATE() AS DATE)	
					
					--PROCEDURE DE CARGA
					EXEC FIRA_PR_CARGA_ST_PATRIMONIO_MOVCC_FINAL @INICIO, @INICIOFIM				
					
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_PATRIMONIO_MOVCC_FINAL'
				  SET @IDPROCESSO	 = 6

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_PATRIMONIO_MOVCC_FINAL', 7
			END
			PRINT 'FIM ST_PATRIMONIO_MOVCC_FINAL'		
		
		END
	---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
	
	
		IF  (@PROCESSO_INI = 8)
		BEGIN 
			/**********************	
				ST_RELATORIO_TRANF_CUST
			***********************/
			PRINT 'INICIO ST_RELATORIO_TRANF_CUST'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_RELATORIO_TRANF_CUST', 8
			BEGIN TRANSACTION
				BEGIN TRY
					
					SET @INICIO = NULL	
					SET @INICIO = ISNULL((SELECT CAST(MAX(DATA_MVTO) AS DATETIME) - @DIAS_REPROC FROM ST_RELATORIO_TRANF_CUST), @DT_DEFAULT)
					SET @INICIOFIM = NULL
					SET @INICIOFIM = CAST(GETDATE() AS DATE)	
					
					--PROCEDURE DE CARGA
					EXEC [FIRA_PR_CARGA_ST_RELATORIO_TRANF_CUST] @INICIO, @INICIOFIM				
					
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_RELATORIO_TRANF_CUST'
				  SET @IDPROCESSO	 = 8

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_RELATORIO_TRANF_CUST', 8
			END
			PRINT 'FIM ST_RELATORIO_TRANF_CUST'		
		
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
		SET @SUCESSO	= 0 
		SET @TIPO 		= 3 
		SET @PROCESSO 	= @PROCESSO_CARGA
		SET @IDPROCESSO = 9992

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO
		
END CATCH

IF(@SUCESSO = 1)
BEGIN
		
		EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,@PROCESSO_CARGA,9992
END
PRINT 'FIM DA CARGA CADASTRO'