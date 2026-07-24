CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_08]
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
		
	   ---VARIAVEIS DO PROCESSO DE EXECUCÃO DA CARGA
	   ,@PROCESSO_INI  INT
	   ,@PROCESSO_FIM INT
		
	   ---VARIAVEIS PARA CARGA
	   ,@PREGAO SMALLDATETIME
	   ,@AUX INT
	   ,@DIA_UTIL INT
	   ,@contador int
	  



/** COLOCAR A DATA DE PROCESSAMENTO OU REPROCESSAMENTO **/
SET @PREGAO = (CAST(GETDATE() AS DATE))

/** PEGA O DIA DO PREGAO **/
SET @AUX 	= (SELECT DAY(@PREGAO))

/** PEGA O TERCEIRO DIA UTIL DO MES **/
SET @DIA_UTIL = DBO.DIA_UTIL(@PREGAO)


/** NUMERO DO PROCESSO QUE IRÁ INICIALIZAR **/
SET @PROCESSO_INI = 1

/** NUMERO DO PROCESSO QUE IRÁ FINALIZAR   **/
SET @PROCESSO_FIM = 9



IF @DIA_UTIL = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'DIA_UTIL')
BEGIN

	---------------------------------------------------------------------------------------------
	------------------			COMEÇO DA CARGA			     ------------------------------------
	---------------------------------------------------------------------------------------------
	PRINT 'CARGA ALERTA 08'
	EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'CARGA_ALERTA_08', 9996
	BEGIN TRY

		---------------------------------------------------------------------------------------------
		-----------------    FILA DE EXECUCÃO DOS PROCESSOS DE CARGA      ---------------------------
		---------------------------------------------------------------------------------------------
		WHILE @PROCESSO_INI <= @PROCESSO_FIM
		BEGIN

		IF  (@PROCESSO_INI = 1)
			BEGIN

				/*****************************************
					ST_ALERT_CHURNING_BOVESPA_02
				*****************************************/
				PRINT 'INICIO ST_ALERT_CHURNING_BOVESPA_02'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_CHURNING_BOVESPA_02', 1
				BEGIN TRANSACTION
					BEGIN TRY

						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_CHURNING_BOVESPA_02')
						if @contador > 0 
						begin
						--PROCEDURE DE CARGA
						EXEC [FIRA_PR_CARGA_ALERT_08_CHURNING_BOVESPA_02] @PREGAO, @AUX
						end
					 
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_CHURNING_BOVESPA_02'
						SET @IDPROCESSO = 1

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_CHURNING_BOVESPA_02', 1
				END
				PRINT 'FIM ST_ALERT_CHURNING_BOVESPA_02'

			END
		  ---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 2)
			BEGIN

				/*****************************************
					ST_ALERT_INSIDER_TRADING_02
				*****************************************/
				PRINT 'INICIO ST_ALERT_INSIDER_TRADING_02'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_INSIDER_TRADING_02', 2
				BEGIN TRANSACTION
					BEGIN TRY
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_INSIDER_TRADING_02')
						if @contador > 0 
						begin
						--PROCEDURE DE CARGA
						EXEC [FIRA_PR_CARGA_ALERT_08_INSIDER_TRADING_02] @PREGAO, @AUX			 
						end
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_INSIDER_TRADING_02'
						SET @IDPROCESSO = 2

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_INSIDER_TRADING_02', 2
				END
				PRINT 'FIM ST_ALERT_INSIDER_TRADING_02'

			END		   
		   
		   
			-------------------------------------------------------------------------------------------
			-------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 3)
			BEGIN

				/*****************************************
					ST_ALERT_OMC_01
				*****************************************/
				PRINT 'INICIO ST_ALERT_OMC_01'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_OMC_01', 3
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_OMC_01')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_OMC_01] @PREGAO, @AUX
						end
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_OMC_01'
						SET @IDPROCESSO = 3

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_OMC_01', 3
				END
				PRINT 'FIM ST_ALERT_OMC_01'

			END
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 4)
			BEGIN

				/*****************************************
					ST_ALERT_OMC_BMF_01
				*****************************************/
				PRINT 'INICIO ST_ALERT_OMC_BMF_01'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_OMC_BMF_01', 4
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_OMC_BMF_01')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_OMC_BMF_01] @PREGAO, @AUX
						end
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_OMC_BMF_01'
						SET @IDPROCESSO = 4

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_OMC_BMF_01', 4
				END
				PRINT 'FIM ST_ALERT_OMC_BMF_01'

			END			
				-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 5)
			BEGIN
				/*****************************************
					ST_ALERT_OMG_BMF
				*****************************************/
				PRINT 'INICIO ST_ALERT_OMG_BMF'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_OMG_BMF', 5
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_OMC_BMF_01')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_OMG_BMF] @PREGAO, @AUX
						end
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_OMG_BMF'
						SET @IDPROCESSO = 5

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_OMG_BMF', 5
				END
				PRINT 'FIM ST_ALERT_OMG_BMF'

			END	
			
				
		
		    -----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 6)
			BEGIN

				/*****************************************
					OMG BOVESPA
				*****************************************/
				PRINT 'INICIO ST_ALERT_OMG_BOVESPA'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_OMG_BOVESPA', 6
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_OMG_BOVESPA')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_OMG_BOVESPA] @PREGAO, @AUX
						end
						
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_OMG_BOVESPA'
						SET @IDPROCESSO = 6

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_OMG_BOVESPA', 6
				END
				PRINT 'FIM ST_ALERT_OMG_BOVESPA'

			END			

			-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			
			
			
			IF  (@PROCESSO_INI = 7)
			BEGIN

				/*****************************************
					OSCILACAO
				*****************************************/
				PRINT 'INICIO ST_ALERT_OSCILACAO'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_OSCILACAO', 7
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_OSCILACAO')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_OSCILACAO] @PREGAO, @AUX
						end
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_OSCILACAO'
						SET @IDPROCESSO = 7

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_OSCILACAO', 7
				END
				PRINT 'FIM ST_ALERT_OSCILACAO'

			END			
			-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			
			
			
			IF  (@PROCESSO_INI = 8)
			BEGIN

				/*****************************************
					OSCILACAO
				*****************************************/
				PRINT 'INICIO ST_ALERT_EMISSOR_VINCULADO'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_EMISSOR_VINCULADO', 8
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_EMISSOR_VINCULADO')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_08_EMISSOR_VINCULADO] @PREGAO, @AUX
						end						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_EMISSOR_VINCULADO'
						SET @IDPROCESSO = 8

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_EMISSOR_VINCULADO', 8
				END
				PRINT 'FIM ST_ALERT_EMISSOR_VINCULADO'

			END			
				-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			
			
			
			IF  (@PROCESSO_INI = 9)
			BEGIN

				/*****************************************
					PAINEL_ALERTAS
				*****************************************/
				PRINT 'INICIO ST_RELATORIO_PAINEL_ALERTAS_CVM'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_RELATORIO_PAINEL_ALERTAS_CVM', 9
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA						 
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_RELATORIO_PAINEL_ALERTAS_CVM')
						if @contador >= 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_RELATORIO] @PREGAO, @AUX
						end
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_RELATORIO_PAINEL_ALERTAS_CVM'
						SET @IDPROCESSO = 9

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_RELATORIO_PAINEL_ALERTAS_CVM', 9
				END
				PRINT 'FIM ST_RELATORIO_PAINEL_ALERTAS_CVM'

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
		SET @ERROR_MESSAGE  = ERROR_MESSAGE()		
		SET @PROCESSO 		= 'CARGA_ALERTA_08'
		SET @IDPROCESSO 	= 9996

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO  RAISERROR(@ERROR_MESSAGE,16,1)
			
	END CATCH

	IF(@SUCESSO = 1)
	BEGIN

		EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'CARGA_ALERTA_08',9996
	END
	PRINT 'FIM DA CARGA ALERTA 08'


END --IF FINAL