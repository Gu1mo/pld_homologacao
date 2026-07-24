CREATE PROCEDURE [dbo].[PR_RelatorioGeralKYCStatusUpdate]
(
	@IdUsuario int,
	@Status nvarchar(50),
	@ClientIdentity varchar(2048)
)
AS
update RelatorioGeralKYCAgendamento set Classificacao = @Status where Id = @IdUsuario