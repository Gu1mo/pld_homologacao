CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_BOVESPA]
--WITH ENCRYPTION
AS


DECLARE @ERROR_NUMBER INT
	   ,@ERROR_MESSAGE NVARCHAR(200)
	   ,@ERROR_LINE INT
	   ,@ERRO VARCHAR(200)
	   ,@SUCESSO BIT = 1
	   ,@TIPO INT 
	   ,@IDPROCESSO INT
	   ,@PROCESSO VARCHAR(20)
	   ,@PROCESSO_CARGA VARCHAR(20)
		
	   ---VARIAVEIS DO PROCESSO DE EXECUCÃO DA CARGA
	   ,@PROCESSO_INI  INT
	   ,@PROCESSO_FIM INT
		
	   ---VARIAVEIS PARA CARGA
	   ,@PREGAO DATETIME
	   ,@PREGAOFIM DATETIME
	   ,@DT_DEFAULT DATETIME 
	   ,@DIAS_REPROC INT
	   ,@CD_CONTRAPARTE INT

SET @DT_DEFAULT = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'DT_DEFAULT')
SET @DIAS_REPROC = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'REPROCESSAMENTO') 			/** COLOCAR A QUANTIDADE DE DIAS DE REPROCESSAMENTO **/


SET @PROCESSO_CARGA = 'CARGA_BOVESPA' /** NOME DA CARGA PRINCIAL **/
SET @CD_CONTRAPARTE = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'CD_CONTRAPARTE')		      /** COLOCAR O CODIGO DA CORRETORA PARA O PROCESSO DE DAYTRADE **/	 
	
			
SET @PROCESSO_INI = 1	/** NUMERO DO PROCESSO QUE IRÁ INICIALIZAR 				**/
SET @PROCESSO_FIM = 15	/** NUMERO DO PROCESSO QUE IRÁ FINALIZAR 				**/


---------------------------------------------------------------------------------------------
------------------			COMEÇO DA CARGA			     ------------------------------------
---------------------------------------------------------------------------------------------
PRINT 'CARGA BOVESPA'
EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1, @PROCESSO_CARGA, 9993
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
			/****************	
				ST_CORRETORA
			****************/
			PRINT 'INICIO ST_CORRETORA'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_CORRETORA', 1
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					EXEC FIRA_PR_CARGA_ST_CORRETORA
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER	 = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CORRETORA'
				  SET @IDPROCESSO	 = 1

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2,'ST_CORRETORA', 1
			END
			PRINT 'FIM ST_CORRETORA'

		END
		
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------


		IF  (@PROCESSO_INI = 2)
		BEGIN 
			/****************	
				ST_CORRETAGEM_ORDEM
			****************/
			PRINT 'INICIO ST_CORRETAGEM_ORDEM'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_CORRETAGEM_ORDEM', 2
			BEGIN TRANSACTION
				BEGIN TRY

					SET @PREGAO = NULL
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_NEGOCIO) - @DIAS_REPROC AS DATE)  FROM ST_CORRETAGEM_ORDEM) ,@DT_DEFAULT)
					SET @PREGAOFIM = NULL
					SET @PREGAOFIM = (CAST(GETDATE() AS DATE))


					--PROCEDURE DE CARGA
					EXEC FIRA_PR_CARGA_ST_CORRETAGEM_ORDEM @PREGAO, @PREGAOFIM
				
				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CORRETAGEM_ORDEM'
				  SET @IDPROCESSO	 = 2

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2, 'ST_CORRETAGEM_ORDEM', 2
			END
			PRINT 'FIM ST_CORRETAGEM_ORDEM'

		END

	
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------


		IF  (@PROCESSO_INI = 3)
		BEGIN 
			/**********************	
				ST_PERIODO
			***********************/
			PRINT 'INICIO ST_PERIODO'	
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,1,'ST_PERIODO', 3
			BEGIN TRANSACTION
				BEGIN TRY
					
					--PROCEDURE DE CARGA
					EXEC FIRA_PR_CARGA_ST_PERIODO

				
				END TRY

			BEGIN CATCH
				  ROLLBACK TRANSACTION
				  SET @SUCESSO			= 0 
				  SET @ERROR_NUMBER 	= ERROR_NUMBER() 
				  SET @ERROR_MESSAGE	= @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE 		= ERROR_LINE() 
				  SET @TIPO 			= 3 
				  SET @PROCESSO 		= 'ST_PERIODO'
				  SET @IDPROCESSO 		= 3

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,@TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE,2,'ST_PERIODO', 3
			END
			PRINT 'FIM ST_PERIODO'	
			
		END
	
	
	
	---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 4)
		BEGIN 
		
			/************************
				ST_DAYTRADE_DETALHE	
			************************/
			PRINT 'INICIO ST_DAYTRADE_DETALHE'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_DAYTRADE_DETALHE', 4
			BEGIN TRANSACTION
				BEGIN TRY
							
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT MAX(DT_PREGAO_COMPROU) - @DIAS_REPROC FROM ST_DAYTRADE_DETALHE), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					
					EXEC [FIRA_PR_CARGA_ST_DAYTRADE_DETALHE]  @PREGAO, @PREGAOFIM, @CD_CONTRAPARTE
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DAYTRADE_DETALHE'
				  SET @IDPROCESSO	 = 4

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_DAYTRADE_DETALHE',4
			END
			PRINT 'FIM ST_DAYTRADE_DETALHE'	
			
		END
		
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 5)
		BEGIN 
		
			/************************
				ST_DAYTRADE_RESUMO	
			************************/
			PRINT 'INICIO ST_DAYTRADE_RESUMO'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_DAYTRADE_RESUMO', 5
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PREGAO_COMPROU) - @DIAS_REPROC AS DATE) FROM ST_DAYTRADE_RESUMO), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					
					EXEC [FIRA_PR_CARGA_ST_DAYTRADE_RESUMO] @PREGAO, @PREGAOFIM 
					
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DAYTRADE_RESUMO'
				  SET @IDPROCESSO	 = 5

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_DAYTRADE_RESUMO',5
			END
			PRINT 'FIM ST_DAYTRADE_RESUMO'	
			
		END		
		
				
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 6)
		BEGIN 
		
			/************************
				ST_DIRETAS_BVSP	
			************************/
			PRINT 'INICIO ST_DIRETAS_BVSP'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_DIRETAS_BVSP', 6
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_DIRETAS_BVSP), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					
					EXEC [FIRA_PR_CARGA_ST_DIRETAS_BVSP] @PREGAO, @PREGAOFIM 
					
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_DIRETAS_BVSP'
				  SET @IDPROCESSO	 = 6

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_DIRETAS_BVSP',6
			END
			PRINT 'FIM ST_DIRETAS_BVSP'	
			
		END		
			
				
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 7)
		BEGIN 
		
			/************************
				ST_CONTROLE_VINCULADOS	
			************************/
			PRINT 'INICIO ST_CONTROLE_VINCULADOS'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_CONTROLE_VINCULADOS', 7
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_CONTROLE_VINCULADOS), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					
					EXEC [FIRA_PR_CARGA_ST_CONTROLE_VINCULADOS] @PREGAO, @PREGAOFIM 
					
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CONTROLE_VINCULADOS'
				  SET @IDPROCESSO	 = 7

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_CONTROLE_VINCULADOS', 7
			END
			PRINT 'FIM ST_CONTROLE_VINCULADOS'	
			
		END	

	
					
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 8)
		BEGIN 
		
			/************************
				ST_RESUMO_DIRETAS_BVSP	
			************************/
			PRINT 'INICIO ST_RESUMO_DIRETAS_BVSP'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_RESUMO_DIRETAS_BVSP', 8
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_RESUMO_DIRETAS_BVSP), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					
					EXEC [FIRA_PR_CARGA_ST_RESUMO_DIRETAS_BVSP] @PREGAO, @PREGAOFIM 
					
				
				
				END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_RESUMO_DIRETAS_BVSP'
				  SET @IDPROCESSO	 = 8

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_RESUMO_DIRETAS_BVSP', 8
			END
			PRINT 'FIM ST_RESUMO_DIRETAS_BVSP'	
			
		END	
		
				
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 9)
		BEGIN 
		
			/************************
			 ST_SWINGTRADE_BOVESPA	
			************************/
			PRINT 'INICIO ST_SWINGTRADE_BOVESPA'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_SWINGTRADE_BOVESPA', 9
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(PREGAO) - @DIAS_REPROC AS DATE) FROM ST_SWINGTRADE_BOVESPA), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)
					
					EXEC [FIRA_PR_CARGA_ST_SWINGTRADE_BOVESPA] @PREGAO, @PREGAOFIM
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_SWINGTRADE_BOVESPA'
				  SET @IDPROCESSO	 = 9

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_SWINGTRADE_BOVESPA', 9
			END
			PRINT 'FIM ST_SWINGTRADE_BOVESPA'	
			
		END	
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 10)
		BEGIN 
		
			/************************
				ST_MANIPULACAO_BVSP	
			************************/
			PRINT 'INICIO ST_MANIPULACAO_BVSP'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_MANIPULACAO_BVSP', 10
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_MANIPULACAO_BVSP), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)

					
					EXEC [FIRA_PR_CARGA_ST_MANIPULACAO_BVSP] 
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_MANIPULACAO_BVSP'
				  SET @IDPROCESSO	 = 10

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_MANIPULACAO_BVSP', 10
			END
			PRINT 'FIM ST_MANIPULACAO_BVSP'	
			
		END			
		
		IF  (@PROCESSO_INI = 11)
		BEGIN 
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------		
			/************************
				ST_MESA_BVSP	
			************************/
			PRINT 'INICIO ST_MESA_BVSP'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_MESA_BVSP', 11
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_MESA_BVSP), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)

					
					EXEC [FIRA_PR_CARGA_ST_MESA_BVSP] 
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_MESA_BVSP'
				  SET @IDPROCESSO	 = 11

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_MESA_BVSP', 11
			END
			PRINT 'FIM ST_MESA_BVSP'	
			
		END	

		IF  (@PROCESSO_INI = 12)
		BEGIN 
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------		
			/************************
				ST_CARTEIRA_DIARIA	
			************************/
			PRINT 'INICIO ST_CARTEIRA_DIARIA'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_CARTEIRA_DIARIA', 12
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					SET @PREGAO = ISNULL((SELECT CAST(MAX(DATA) - @DIAS_REPROC AS DATE) FROM ST_CARTEIRA_DIARIA), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)

					
					EXEC [FIRA_PR_CARGA_ST_CARTEIRA_DIARIA] @PREGAO, @PREGAOFIM
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CARTEIRA_DIARIA'
				  SET @IDPROCESSO	 = 12

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_CARTEIRA_DIARIA', 12
			END
			PRINT 'FIM ST_CARTEIRA_DIARIA'	
			
		END			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------		
		IF  (@PROCESSO_INI = 13)
		BEGIN 

			/************************
				ST_CARTEIRA_MEDIA_MENSAL	
			************************/
			PRINT 'INICIO ST_CARTEIRA_MEDIA_MENSAL'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_CARTEIRA_MEDIA_MENSAL', 13
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA
					SET @PREGAOFIM = NULL 	
					SET @PREGAOFIM = CAST(GETDATE() AS DATE)

					
					EXEC [FIRA_PR_CARGA_ST_CARTEIRA_MEDIA_MENSAL] @PREGAOFIM
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_CARTEIRA_MEDIA_MENSAL'
				  SET @IDPROCESSO	 = 13

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_CARTEIRA_MEDIA_MENSAL', 13
			END
			PRINT 'FIM ST_CARTEIRA_MEDIA_MENSAL'	
			
		END			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------		
		IF  (@PROCESSO_INI = 14)
		BEGIN 

			/************************
				ST_MESA_AUX_BVSP	
			************************/
			PRINT 'INICIO ST_MESA_AUX_BVSP'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_MESA_AUX_BVSP', 14
			BEGIN TRANSACTION
				BEGIN TRY
							
					--PROCEDURE DE CARGA				
					SET @PREGAO = NULL 	
					--SET @PREGAO = ISNULL((SELECT CAST(MAX(DT_PERIODO) - @DIAS_REPROC AS DATE) FROM ST_MESA_AUX_BVSP), @DT_DEFAULT)
					SET @PREGAOFIM = NULL 	
					--SET @PREGAOFIM = CAST(GETDATE() AS DATE)

					
					EXEC [FIRA_PR_CARGA_ST_MESA_AUX_BVSP] 
					
				
					END TRY

			BEGIN CATCH

				  ROLLBACK TRANSACTION
				  SET @SUCESSO		 = 0 
				  SET @ERROR_NUMBER  = ERROR_NUMBER() 
				  SET @ERROR_MESSAGE = @PROCESSO_CARGA + ' || '+ ERROR_MESSAGE() 
				  SET @ERROR_LINE	 = ERROR_LINE() 
				  SET @TIPO			 = 3 
				  SET @PROCESSO		 = 'ST_MESA_AUX_BVSP'
				  SET @IDPROCESSO	 = 14

				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

			END CATCH

			IF(@SUCESSO = 1)
			BEGIN
				  COMMIT TRANSACTION
				  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_MESA_AUX_BVSP', 14
			END
			PRINT 'FIM ST_MESA_AUX_BVSP'	
			
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
		SET @IDPROCESSO		= 9993

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO  RAISERROR(@ERROR_MESSAGE,16,1)
		
END CATCH

IF(@SUCESSO = 1)
BEGIN

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2, @PROCESSO_CARGA, 9993
END
PRINT 'FIM DA CARGA BOVESPA'