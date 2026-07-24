--select * from RelatorioGeralKYCAgendamento
--exec PR_RelatorioGeralKYCResultadosV2 null, null, null, null, null, null, '01b8a65b09bbe90af5707894a3f7b704fab4d2a9f697e5289003ee0af082fece'
CREATE PROCEDURE [dbo].[PR_RelatorioGeralKYCResultadosV2]
(
	@Nome nvarchar(1000),
	@CpfCnpj nvarchar(20),
	@Risco nvarchar(30),
	@Status nvarchar(50),
	@DataInicial date,
	@DataFinal date,
	@ClientIdentity varchar(2048)
)
AS
BEGIN

	SELECT @Nome = LTRIM(@Nome)
	SELECT @Nome = DBO.REMOVERDIACRITICOS(@Nome)
	DECLARE @NOMESEPARADO TABLE(WORD VARCHAR(500))
	INSERT INTO @NOMESEPARADO SELECT value FROM STRING_SPLIT(@Nome, ' ')
	DECLARE @QUANTIDADENOMES INT = (SELECT COUNT(*) FROM @NOMESEPARADO)
	DECLARE @CONTAINSITEMS VARCHAR(1000)

	IF @QUANTIDADENOMES = 1
	BEGIN
	SET @CONTAINSITEMS = @Nome
	END
	IF @QUANTIDADENOMES > 1
	BEGIN
	SET @CONTAINSITEMS =
		'NEAR((' +
		(
			SELECT
				STUFF((
					SELECT ', ' + ISNULL(WORD, ' ')
					FROM @NOMESEPARADO
					FOR XML PATH(''), TYPE
				).value('.', 'nvarchar(max)'), 1, 2, '')
		) +
		'), 100, TRUE)';
	END

    IF @CONTAINSITEMS IS NULL
	BEGIN
		SELECT
		a.Id,
		a.CpfCnpj,
		a.Nome,
		a.DataHoraConsulta,
		(
			case when a.Status = 0 and a.Processos = 0 and a.Noticias = 0 then 0
			when (a.Status = 1 or a.Processos = 1 or a.Noticias = 1) or a.DataConclusao is null then 1
			when ((a.Status = 2 or a.Status = 3) and (a.Processos = 2 or a.Processos = 3) and (a.Noticias = 2 or a.Noticias = 3)
			and a.DataConclusao is not null) then 2
			else 2 end
		)  AS Status,
		--CASE WHEN (SELECT t.Status
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id)) IS NULL THEN 0 ELSE
		--(SELECT t.Status
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id))END AS Status,
		(select Classificacao from RelatorioGeralKycAgendamento where id = a.Id) as Classificacao,
		a.DataConclusao as DataConclusao,
		--(SELECT t.DATA_CONCLUSAO
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id)) as DataConclusao,
		(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') as Pep,
		(select count(1)
		FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
		WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) as Processos,
		(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) as Listas,
		(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) as Noticias,
		(select situacao_cadastral from RelatorioGeralKYCRFBPF where id_requisicao = a.Id) as RfbPf,
		(select situacao from RelatorioGeralKYCRFBPJ where id_requisicao = a.Id) as RfbPj
		FROM RelatorioGeralKYCAgendamento a
		WHERE ((a.CpfCnpj LIKE '%' + @CpfCnpj + '%')
		OR (@Nome IS NULL AND @CpfCnpj IS NULL)) AND a.ClientIdentity = @ClientIdentity

		AND ((a.DataHoraConsulta >= @DataInicial OR @DataInicial is null) and (a.DataHoraConsulta <= @DataFinal OR @DataFinal is null))

		AND ((
			case when a.Status = 0 and a.Processos = 0 and a.Noticias = 0 then 0
			when (a.Status = 1 or a.Processos = 1 or a.Noticias = 1) or a.DataConclusao is null then 1
			when ((a.Status = 2 or a.Status = 3) and (a.Processos = 2 or a.Processos = 3) and (a.Noticias = 2 or a.Noticias = 3)
			and a.DataConclusao is not null) then 2
			else 2 end
		) = @Status or @Status is null)

		AND (
			(
				(
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') > 0
					OR
					(select count(1)
					FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
					WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) > 0
					OR
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) > 0
					OR
					(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) > 0
				) AND @Risco = 'Alto'
			)
			OR
			(
				(
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') = 0
					AND
					(select count(1)
					FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
					WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) = 0
					AND
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) = 0
					AND
					(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) = 0
				) AND @Risco = 'Baixo'
			)
			OR
			(
				@Risco IS null
			)
		)
		AND DossiePrincipalID is NULL


		ORDER BY a.DataHoraConsulta desc
	END
	ELSE
	BEGIN
		SELECT
		a.Id,
		a.CpfCnpj,
		a.Nome,
		a.DataHoraConsulta,
		(
			2
		)  AS Status,
		--CASE WHEN (SELECT t.Status
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id)) IS NULL THEN 0 ELSE
		--(SELECT t.Status
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id))END AS Status,
		(select Status from RelatorioGeralKycAgendamento where id = a.Id) as Classificacao,
		a.DataConclusao as DataConclusao,
		--(SELECT t.DATA_CONCLUSAO
		--FROM ST_CONSULTA_TRIBUNAIS_REQUISICAO t
		--WHERE t.ID =
		--(SELECT m.IdRequisicaoProcessos
		--FROM RelatorioGeralKYCMap m
		--WHERE m.IdRequisicaoRelatorioGeral = a.Id)) as DataConclusao,
		(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') as Pep,
		(select count(1)
		FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
		WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) as Processos,
		(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) as Listas,
		(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) as Noticias,
		(select situacao_cadastral from RelatorioGeralKYCRFBPF where id_requisicao = a.Id) as Rfb,
		(select situacao from RelatorioGeralKYCRFBPJ where id_requisicao = a.Id) as RfbPj
		FROM RelatorioGeralKYCAgendamento a
		WHERE ((CONTAINS(Nome, @CONTAINSITEMS) AND (a.CpfCnpj LIKE '%' + @CpfCnpj + '%' OR @CpfCnpj is null))
		OR (@Nome IS NULL AND @CpfCnpj IS NULL)) AND a.ClientIdentity = @ClientIdentity

		AND ((a.DataHoraConsulta >= @DataInicial OR @DataInicial is null) and (a.DataHoraConsulta <= @DataFinal OR @DataFinal is null))

		AND ((
			case when a.Status = 0 and a.Processos = 0 and a.Noticias = 0 then 0
			when (a.Status = 1 or a.Processos = 1 or a.Noticias = 1) or a.DataConclusao is null then 1
			when ((a.Status = 2 or a.Status = 3) and (a.Processos = 2 or a.Processos = 3) and (a.Noticias = 2 or a.Noticias = 3)
			and a.DataConclusao is not null) then 2
			else 2 end
		) = @Status or @Status is null)

		AND (
			(
				(
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') > 0
					OR
					(select count(1)
					FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
					WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) > 0
					OR
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) > 0
					OR
					(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) > 0
				) AND @Risco = 'Alto'
			)
			OR
			(
				(
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id and Lista = 'Pessoas Expostas Politicamente') = 0
					AND
					(select count(1)
					FROM ST_CONSULTA_TRIBUNAIS_PROCESSO_V2
					WHERE IdRequisicao = a.Id and (LOWER(classes) like '%criminal%' or LOWER(assuntos) like '%criminal%')) = 0
					AND
					(select count(1) from RelatorioGeralKYCListas where IdRequisicao = a.Id) = 0
					AND
					(select count(1) from RelatorioGeralKYCNoticias where IdRequisicao = a.Id) = 0
				) AND @Risco = 'Baixo'
			)
			OR
			(
				@Risco IS null
			)
		)
        AND DossiePrincipalID is NULL
		ORDER BY a.DataHoraConsulta desc
	END

END