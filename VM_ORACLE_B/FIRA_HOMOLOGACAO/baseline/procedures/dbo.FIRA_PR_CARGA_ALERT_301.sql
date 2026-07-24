/****** Object:  StoredProcedure [dbo].[FIRA_PR_CARGA_ALERT_301]    Script Date: 25/02/2026 15:50:21 ******/
CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ALERT_301]
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
SET @PROCESSO_FIM = 18



IF @DIA_UTIL = (SELECT MAX(CD_PARAMETRO) FROM ST_CLIENTE_PARAMETROS WHERE DS_PARAMETRO = 'DIA_UTIL')
BEGIN

	---------------------------------------------------------------------------------------------
	------------------			COMEÇO DA CARGA			     ------------------------------------
	---------------------------------------------------------------------------------------------
	PRINT 'CARGA ALERTA 301'
	EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'CARGA_ALERTA_301', 9995
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

			/***************************
				ST_ALERT_ATIVO_RESTRITO
			***************************/
			PRINT 'INICIO ST_ALERT_ATIVO_RESTRITO'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_ATIVO_RESTRITO', 1
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_ATIVO_RESTRITO')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_ATIVO_RESTRITO] @PREGAO, @AUX
					end
					
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_ATIVO_RESTRITO'
					SET @IDPROCESSO = 1

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_ATIVO_RESTRITO', 1
			END
			PRINT 'FIM ST_ALERT_ATIVO_RESTRITO'

		END

		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 2)
		BEGIN

			/************************************
				ST_ALERT_ATULIZACAO_CADASTRAL_01	
			************************************/
			PRINT 'INICIO ST_ALERT_ATULIZACAO_CADASTRAL_01'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_ATULIZACAO_CADASTRAL_01', 2
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_ATULIZACAO_CADASTRAL_01')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_ATULIZACAO_CADASTRAL_01] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_ATULIZACAO_CADASTRAL_01'
					SET @IDPROCESSO = 2

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_ATULIZACAO_CADASTRAL_01', 2
			END
			PRINT 'FIM ST_ALERT_ATULIZACAO_CADASTRAL_01'

		END


		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 3)
		BEGIN

			/************************
				ST_ALERT_LISTA_ATENCAO	
			************************/
			PRINT 'INICIO ST_ALERT_LISTA_ATENCAO'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_LISTA_ATENCAO', 3
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_LISTA_ATENCAO')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_LISTA_ATENCAO] @PREGAO, @AUX
					end
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_LISTA_ATENCAO'
					SET @IDPROCESSO = 3

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_LISTA_ATENCAO', 3
			END
			PRINT 'FIM ST_ALERT_LISTA_ATENCAO'

		END
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
		IF  (@PROCESSO_INI = 4)
		BEGIN

			/************************
				ST_ALERT_MEDIA_BMF_01	
			************************/
			PRINT 'INICIO ST_ALERT_MEDIA_BMF_01'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_MEDIA_BMF_01', 4
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MEDIA_BMF_01')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_MEDIA_BMF_01] @PREGAO, @AUX
					end
				
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_MEDIA_BMF_01'
					SET @IDPROCESSO = 4

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MEDIA_BMF_01', 4
			END
			PRINT 'FIM ST_ALERT_MEDIA_BMF_01'

		END
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------

		IF  (@PROCESSO_INI = 5)
		BEGIN

			/*****************************
				ST_ALERT_MEDIA_BOVESPA_01	
			*****************************/
			PRINT 'INICIO ST_ALERT_MEDIA_BOVESPA_01'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_MEDIA_BOVESPA_01', 5
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MEDIA_BOVESPA_01')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_MEDIA_BOVESPA_01] @PREGAO, @AUX
					end

					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_MEDIA_BOVESPA_01'
					SET @IDPROCESSO = 5

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MEDIA_BOVESPA_01', 5
			END
			PRINT 'FIM ST_ALERT_MEDIA_BOVESPA_01'

		END
			-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 6)
			BEGIN

				/*****************************************
					ST_ALERT_MONEYPASS_BMF
				*****************************************/
				PRINT 'INICIO ST_ALERT_MONEYPASS_BMF'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_MONEYPASS_BMF', 6
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MONEYPASS_BMF')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_301_MONEYPASS_BMF_02] @PREGAO, @AUX
						end
						
						
					
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_MONEYPASS_BMF'
						SET @IDPROCESSO = 6

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MONEYPASS_BMF', 6
				END
				PRINT 'FIM ST_ALERT_MONEYPASS_BMF'

			END
			-----------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------
			IF  (@PROCESSO_INI = 7)
			BEGIN

				/*****************************************
					ST_ALERT_MONEYPASS_BOVESPA
				*****************************************/
				PRINT 'INICIO ST_ALERT_MONEYPASS_BOVESPA'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_MONEYPASS_BOVESPA', 7
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MONEYPASS_BOVESPA')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_301_MONEYPASS_BOVESPA_02] @PREGAO, @AUX
						end
						
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_MONEYPASS_BOVESPA'
						SET @IDPROCESSO = 7

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MONEYPASS_BOVESPA', 7
				END
				PRINT 'FIM ST_ALERT_MONEYPASS_BOVESPA'

			END
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 8)
			BEGIN

				/*****************************************
					ST_ALERT_MONEYPASS_CORRETORA
				*****************************************/
				PRINT 'INICIO ST_ALERT_MONEYPASS_CORRETORA'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_MONEYPASS_CORRETORA', 8
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MONEYPASS_CORRETORA')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_301_MONEYPASS_CORRETORA] @PREGAO, @AUX
						end
						
										
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_MONEYPASS_CORRETORA'
						SET @IDPROCESSO = 8

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MONEYPASS_CORRETORA', 8
				END
				PRINT 'FIM ST_ALERT_MONEYPASS_CORRETORA'

			END
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 9)
			BEGIN

				/*****************************************
					ST_ALERT_MONEYPASS_CORRETORA_BMF
				*****************************************/
				PRINT 'INICIO ST_ALERT_MONEYPASS_CORRETORA_BMF'
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  1, 'ST_ALERT_MONEYPASS_CORRETORA_BMF', 9
				BEGIN TRANSACTION
					BEGIN TRY

						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MONEYPASS_CORRETORA_BMF')
						if @contador > 0 
						begin
						EXEC [FIRA_PR_CARGA_ALERT_301_MONEYPASS_CORRETORA_BMF] @PREGAO, @AUX
						end
						
						
					END TRY

					BEGIN CATCH

						ROLLBACK TRANSACTION
						SET @SUCESSO	= 0 
						SET @ERROR_NUMBER = ERROR_NUMBER() 
						SET @ERROR_MESSAGE = ERROR_MESSAGE() 
						SET @ERROR_LINE = ERROR_LINE() 
						SET @TIPO = 3 
						SET @PROCESSO = 'ST_ALERT_MONEYPASS_CORRETORA_BMF'
						SET @IDPROCESSO = 9

						EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

					END CATCH

				IF(@SUCESSO = 1)
					BEGIN
					COMMIT TRANSACTION
					EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MONEYPASS_CORRETORA_BMF', 9
				END
				PRINT 'FIM ST_ALERT_MONEYPASS_CORRETORA_BMF'

			END
			
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 10)
		BEGIN

			/*********************************
				ST_ALERT_MUDANCA_REPENTINA_01
			*********************************/
			PRINT 'INICIO ST_ALERT_MUDANCA_REPENTINA_01'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_MUDANCA_REPENTINA_01', 10
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_MUDANCA_REPENTINA_01')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_MUDANCA_REPENTINA_01] @PREGAO, @AUX
					end
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_MUDANCA_REPENTINA_01'
					SET @IDPROCESSO = 10

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_MUDANCA_REPENTINA_01', 10
			END
			PRINT 'FIM ST_ALERT_MUDANCA_REPENTINA_01'

		END


		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 11)
		BEGIN

			/******************************
				ST_ALERT_PATRIMONIO_CUSTODIA
			******************************/
			PRINT 'INICIO ST_ALERT_PATRIMONIO_CUSTODIA'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_PATRIMONIO_CUSTODIA', 11
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_PATRIMONIO_CUSTODIA')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_PATRIMONIO_CUSTODIA] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					  ROLLBACK TRANSACTION
					  SET @SUCESSO	= 0 
					  SET @ERROR_NUMBER = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE = ERROR_LINE() 
					  SET @TIPO = 3 
					  SET @PROCESSO = 'ST_ALERT_PATRIMONIO_CUSTODIA'
					  SET @IDPROCESSO = 11

					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_PATRIMONIO_CUSTODIA', 11
			END
			PRINT 'FIM ST_ALERT_PATRIMONIO_CUSTODIA'

		END
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 12)
		BEGIN

			/**********************************
				ST_ALERT_PATRIMONIO_MOVIMENTO
			**********************************/
			PRINT 'INICIO ST_ALERT_PATRIMONIO_MOVIMENTO'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_PATRIMONIO_MOVIMENTO', 12
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_PATRIMONIO_MOVIMENTO')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_PATRIMONIO_MOVIMENTO] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					  ROLLBACK TRANSACTION
					  SET @SUCESSO	= 0 
					  SET @ERROR_NUMBER = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE = ERROR_LINE() 
					  SET @TIPO = 3 
					  SET @PROCESSO = 'ST_ALERT_PATRIMONIO_MOVIMENTO'
					  SET @IDPROCESSO = 12

					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_PATRIMONIO_MOVIMENTO', 12
			END
			PRINT 'FIM ST_ALERT_PATRIMONIO_MOVIMENTO'

		END	
	
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 13)
		BEGIN

			/******************************
				ST_ALERT_PATRIMONIO_NETTING
			******************************/
			PRINT 'INICIO ST_ALERT_PATRIMONIO_NETTING'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_PATRIMONIO_NETTING', 13
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_PATRIMONIO_NETTING')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_PATRIMONIO_NETTING] @PREGAO, @AUX
					end
					
				
				END TRY

				BEGIN CATCH

					  ROLLBACK TRANSACTION
					  SET @SUCESSO	= 0 
					  SET @ERROR_NUMBER = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE = ERROR_LINE() 
					  SET @TIPO = 3 
					  SET @PROCESSO = 'ST_ALERT_PATRIMONIO_NETTING'
					  SET @IDPROCESSO = 13

					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_PATRIMONIO_NETTING', 13
			END
			PRINT 'FIM ST_ALERT_PATRIMONIO_NETTING'

		END	
		

		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 14)
		BEGIN

			/**********************************
				ST_ALERT_PATRIMONIO_TRANF_CUST
			**********************************/
			PRINT 'INICIO ST_ALERT_PATRIMONIO_TRANF_CUST'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_PATRIMONIO_TRANF_CUST', 14
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_PATRIMONIO_TRANF_CUST')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_PATRIMONIO_TRANF_CUST] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					  ROLLBACK TRANSACTION
					  SET @SUCESSO	= 0 
					  SET @ERROR_NUMBER = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE = ERROR_LINE() 
					  SET @TIPO = 3 
					  SET @PROCESSO = 'ST_ALERT_PATRIMONIO_TRANF_CUST'
					  SET @IDPROCESSO = 14

					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_PATRIMONIO_TRANF_CUST', 14
			END
			PRINT 'FIM ST_ALERT_PATRIMONIO_TRANF_CUST'

		END	

		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
				
		IF  (@PROCESSO_INI = 15)
		BEGIN

			/************************
				ST_ALERT_PROCURADOR_02	
			************************/
			PRINT 'INICIO ST_ALERT_PROCURADOR_02'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_PROCURADOR_02', 15
			BEGIN TRANSACTION
				BEGIN TRY
		
					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_PROCURADOR_02')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_PROCURADOR_02] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_PROCURADOR_02'
					SET @IDPROCESSO = 15

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_PROCURADOR_02', 15
			END
			PRINT 'FIM ST_ALERT_PROCURADOR_02'

		END

		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
				IF  (@PROCESSO_INI =16)
				BEGIN
				/****************	
					ST_ALERT_RANKING_DAYTRADE_BMF
				****************/
				PRINT 'INICIO ST_ALERT_RANKING_DAYTRADE_BMF'	
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_RANKING_DAYTRADE_BMF',16
				BEGIN TRANSACTION
					BEGIN TRY
	
						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_RANKING_DAYTRADE_BMF')
						if @contador > 0 
						begin
						EXEC FIRA_PR_CARGA_ALERT_301_RANKING_DAYTRADE_BMF @PREGAO , @AUX
						end
					
					
					END TRY
	
				BEGIN CATCH
					  ROLLBACK TRANSACTION
					  SET @SUCESSO		 = 0 
					  SET @ERROR_NUMBER	 = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE	 = ERROR_LINE() 
					  SET @TIPO			 = 3 
					  SET @PROCESSO		 = 'ST_ALERT_RANKING_DAYTRADE_BMF'
					  SET @IDPROCESSO	 = 16
	
					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)
	
				END CATCH
	
				IF(@SUCESSO = 1)
				BEGIN
					  COMMIT TRANSACTION
					  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2,'ST_ALERT_RANKING_DAYTRADE_BMF', 16
				END
				PRINT 'FIM ST_ALERT_RANKING_DAYTRADE_BMF'
		END
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
				IF  (@PROCESSO_INI =17)
				BEGIN
				/****************	
					ST_ALERT_RANKING_DAYTRADE_BVSP
				****************/
				PRINT 'INICIO ST_ALERT_RANKING_DAYTRADE_BVSP'	
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_RANKING_DAYTRADE_BVSP',17
				BEGIN TRANSACTION
					BEGIN TRY
	
						--PROCEDURE DE CARGA
						set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_RANKING_DAYTRADE_BVSP')
						if @contador > 0 
						begin
						EXEC FIRA_PR_CARGA_ALERT_301_RANKING_DAYTRADE_BVSP @PREGAO , @AUX
						end
					
					
					END TRY
	
				BEGIN CATCH
					  ROLLBACK TRANSACTION
					  SET @SUCESSO		 = 0 
					  SET @ERROR_NUMBER	 = ERROR_NUMBER() 
					  SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					  SET @ERROR_LINE	 = ERROR_LINE() 
					  SET @TIPO			 = 3 
					  SET @PROCESSO		 = 'ST_ALERT_RANKING_DAYTRADE_BVSP'
					  SET @IDPROCESSO	 = 17
	
					  EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)
	
				END CATCH
	
				IF(@SUCESSO = 1)
				BEGIN
					  COMMIT TRANSACTION
					  EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 2,'ST_ALERT_RANKING_DAYTRADE_BVSP', 17
				END
				PRINT 'FIM ST_ALERT_RANKING_DAYTRADE_BVSP'
		END
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 18)
		BEGIN

			/*****************************************
				ST_ALERT_TRANSFERENCIA_FINANCEIRA_01
			*****************************************/
			PRINT 'INICIO ST_ALERT_TRANSFERENCIA_FINANCEIRA_01'
			EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 1,'ST_ALERT_TRANSFERENCIA_FINANCEIRA_01', 18
			BEGIN TRANSACTION
				BEGIN TRY

					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_TRANSFERENCIA_FINANCEIRA_01')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_TRANSFERENCIA_FINANCEIRA_01] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_TRANSFERENCIA_FINANCEIRA_01'
					SET @IDPROCESSO = 18

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'ST_ALERT_TRANSFERENCIA_FINANCEIRA_01',18
			END
			PRINT 'FIM ST_ALERT_TRANSFERENCIA_FINANCEIRA_01'

		END


		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		IF  (@PROCESSO_INI = 19)
		BEGIN

			/*****************************************
				ST_ALERT_TRANSFERENCIA_FINANCEIRA_02
			*****************************************/
			PRINT 'INICIO ST_ALERT_TRANSFERENCIA_FINANCEIRA_02'
			EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE, 1,'ST_ALERT_TRANSFERENCIA_FINANCEIRA_02', 19
			BEGIN TRANSACTION
				BEGIN TRY
								
					--PROCEDURE DE CARGA
					set @contador = null
						set @contador = (select top 1 count(*)tt from relatorioAlertas where descricao = 'ST_ALERT_TRANSFERENCIA_FINANCEIRA_02')
						if @contador > 0 
						begin
					EXEC [FIRA_PR_CARGA_ALERT_301_TRANSFERENCIA_FINANCEIRA_02] @PREGAO, @AUX
					end
					
					
				
				END TRY

				BEGIN CATCH

					ROLLBACK TRANSACTION
					SET @SUCESSO	= 0 
					SET @ERROR_NUMBER = ERROR_NUMBER() 
					SET @ERROR_MESSAGE = ERROR_MESSAGE() 
					SET @ERROR_LINE = ERROR_LINE() 
					SET @TIPO = 3 
					SET @PROCESSO = 'ST_ALERT_TRANSFERENCIA_FINANCEIRA_02'
					SET @IDPROCESSO = 19

					EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, @TIPO,@PROCESSO,@IDPROCESSO RAISERROR(@ERROR_MESSAGE,16,1)

				END CATCH

			IF(@SUCESSO = 1)
				BEGIN
				COMMIT TRANSACTION
				EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  2, 'ST_ALERT_TRANSFERENCIA_FINANCEIRA_02', 19
			END
			PRINT 'FIM ST_ALERT_TRANSFERENCIA_FINANCEIRA_02'

		END
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
			
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
		SET @PROCESSO 		= 'CARGA_ALERTA_301'
		SET @IDPROCESSO 	= 9995

		EXEC FIRA_PR_LOG @ERROR_NUMBER, @ERROR_MESSAGE, @ERROR_LINE,  @TIPO, @PROCESSO, @IDPROCESSO  RAISERROR(@ERROR_MESSAGE,16,1)
			
	END CATCH

	IF(@SUCESSO = 1)
	BEGIN

		EXEC FIRA_PR_LOG @ERROR_NUMBER,@ERROR_MESSAGE,@ERROR_LINE, 2,'CARGA_ALERTA_301',9995
	END
	PRINT 'FIM DA CARGA ALERTA 301'


END --IF FINAL