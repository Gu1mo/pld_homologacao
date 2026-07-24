CREATE PROCEDURE [dbo].[PR_RelatorioGeralKYCGeracaoV3]
(
    @IdRequisicao int
)
WITH RECOMPILE
AS
BEGIN

	DECLARE @UUID VARCHAR(MAX);
	SELECT @UUID = (SELECT ProceedingsUUID FROM RelatorioGeralKYCAgendamento where Id = @IdRequisicao);

	DECLARE @Listas VARCHAR(MAX)
	SELECT @Listas = COALESCE(@Listas + ' ', '') +
	'{=' +
		CASE WHEN Lista IS NULL THEN '-' ELSE Lista END + ' (' + CASE WHEN Fonte IS NULL THEN '-' ELSE Fonte END + ')'  + '=,=' +
		CASE WHEN Nome IS NULL THEN '-' ELSE Nome END + '=,=' +
		CASE WHEN CpfCnpj IS NULL THEN '-' ELSE CpfCnpj END + '=,=' +
		CASE WHEN CargoExercido IS NULL THEN '-' ELSE CargoExercido END + '=,=' +
		FORMAT(DataAtualizacao, 'dd/MM/yy') + '=,=' +
		CASE WHEN Detalhes IS NULL THEN '-' ELSE Detalhes END + '=,=' +
		CASE WHEN Territorio IS NULL THEN '-' ELSE Territorio END +
	'=}'

	FROM RelatorioGeralKYCListas
	WHERE IdRequisicao = @IdRequisicao

	DECLARE @ListasTerritorio VARCHAR(MAX)
	SELECT @ListasTerritorio = COALESCE(@ListasTerritorio + ' ', '') +
	'{=' + S.Nome + ' (' + F.Sigla + ')'  + '=}'

	FROM RelatorioGeralKYCListasTerritorio LT
	LEFT JOIN ListaAtencaoSublista S ON S.Id = LT.IdSublista
	RIGHT JOIN ListaAtencaoFonte F ON S.IdFonte = F.Id
	WHERE IdRequisicao = @IdRequisicao

    DECLARE @NomesListas VARCHAR(MAX)
	SELECT @NomesListas = COALESCE(@NomesListas + ' ', '') +
    '{=' +
        s.Nome +
		' ' +
       '(' + f.Sigla + ')' +
	'=}'
	FROM ListaAtencaoSublista s left join ListaAtencaoFonte f on f.Id = s.IdFonte
	WHERE s.Nome NOT IN ('Jurisdições de Alto Risco ou Monitoradas', 'Section 311 of the USA PATRIOT Act', 'Paraísos Fiscais', 'Municipios Beneficiários de Parcela da CFEM', 'Corruption Perceptions Index', 'Municípios da Faixa de Fronteira', 'US States Sponsors of Terrorism', 'Áreas embargadas por desmatamento ilegal')

	DECLARE @NomesListasTerritorio VARCHAR(MAX)
	SELECT @NomesListasTerritorio = COALESCE(@NomesListasTerritorio + ' ', '') +
    '{=' +
        s.Nome +
		' ' +
       '(' + f.Sigla + ')' +
	'=}'
	FROM ListaAtencaoSublista s left join ListaAtencaoFonte f on f.Id = s.IdFonte
	WHERE s.Id IN (19, 20, 32, 33, 34, 47, 57, 65)


	DECLARE @Noticias VARCHAR(MAX)
	SELECT @Noticias = COALESCE(@Noticias + ' ', '') +
	'{=' +
		titulo  + '=,=' +
		[url] + '=,=' +
		descricao + '=,=' +
		FORMAT(dataPublicacao, 'yyyy-MM-dd') + '=,=' +
		fonte + '=,=' +
		sentimento + '=,=' +
		keywords + '=,=' +
		[match] + '=,=' +
	'=}'

	FROM RelatorioGeralKYCNoticias
	WHERE IdRequisicao = @IdRequisicao

	DECLARE @Processos VARCHAR(MAX)
	SELECT @Processos = COALESCE(@Processos + ' ', '') +
	'{=' +
		CASE WHEN classe IS NULL THEN '-' ELSE classe END + '=,=' +
		CASE WHEN distribuicao IS NULL THEN '-' ELSE distribuicao END + '=,=' +
		CASE WHEN documento IS NULL THEN '-' ELSE documento END + '=,=' +
		CASE WHEN tipo_pessoa IS NULL THEN '-' ELSE tipo_pessoa END + '=,=' +
		CASE WHEN partes IS NULL THEN '-' ELSE partes END + '=,=' +
		CASE WHEN numero IS NULL THEN '-' ELSE numero END + '=,=' +
		CASE WHEN area IS NULL THEN '-' ELSE area END + '=,=' +
		CASE WHEN vara IS NULL THEN '-' ELSE vara END + '=,=' +
		CASE WHEN local_fisico IS NULL THEN '-' ELSE local_fisico END + '=,=' +
		CASE WHEN assunto IS NULL THEN '-' ELSE assunto END + '=,=' +
		CASE WHEN outros_assuntos IS NULL THEN '-' ELSE outros_assuntos END + '=,=' +
		CASE WHEN controle IS NULL THEN '-' ELSE controle END + '=,=' +
		CASE WHEN juiz IS NULL THEN '-' ELSE juiz END + '=,=' +
		CASE WHEN valor_acao IS NULL THEN '-' ELSE valor_acao END + '=,=' +
		CASE WHEN movimentacao IS NULL THEN '-' ELSE movimentacao END + '=,=' +
		CASE WHEN [url] IS NULL THEN '-' ELSE url END + '=,=' +
	'=}'
	FROM RelatorioGeralKYCProcessos
	WHERE uuid = @UUID

	DECLARE @ProcessosPas VARCHAR(MAX)
	SELECT @ProcessosPas = COALESCE(@ProcessosPas + ' ', '') +
	'{=' +
		CASE WHEN movimentacoes IS NULL THEN '-' ELSE movimentacoes END + '=,=' +
		CASE WHEN fase_atual IS NULL THEN '-' ELSE fase_atual END + '=,=' +
		CASE WHEN subfase_atual IS NULL THEN '-' ELSE subfase_atual END + '=,=' +
		CASE WHEN data_ultima_mudanca_fase_subfase IS NULL THEN '-' ELSE CAST(data_ultima_mudanca_fase_subfase AS VARCHAR) END + '=,=' +
		CASE WHEN local_atual IS NULL THEN '-' ELSE local_atual END + '=,=' +
		CASE WHEN data_ultima_movimentacao_local IS NULL THEN '-' ELSE CAST(data_ultima_movimentacao_local AS VARCHAR) END + '=,=' +
		CASE WHEN numero IS NULL THEN '-' ELSE numero END + '=,=' +
		CASE WHEN assunto_objeto IS NULL THEN '-' ELSE assunto_objeto END + '=,=' +
		CASE WHEN data_abertura IS NULL THEN '-' ELSE CAST(data_abertura AS VARCHAR) END + '=,=' +
		CASE WHEN encarregado_instrucao IS NULL THEN '-' ELSE encarregado_instrucao END + '=,=' +
		CASE WHEN acusados IS NULL THEN '-' ELSE acusados END + '=,=' +
	'=}'

	FROM RelatorioGeralKYCCVMPAS
	WHERE IdRequisicao = @IdRequisicao

	DECLARE @ProcessosPad VARCHAR(MAX)
	SELECT @ProcessosPad = COALESCE(@ProcessosPad + ' ', '') +
	'{=' +
		CASE WHEN data IS NULL THEN '-' ELSE data END + '=,=' +
		CASE WHEN origem IS NULL THEN '-' ELSE origem END + '=,=' +
		CASE WHEN destino IS NULL THEN '-' ELSE destino END + '=,=' +
		CASE WHEN processo IS NULL THEN '-' ELSE processo END + '=,=' +
		CASE WHEN interessados IS NULL THEN '-' ELSE interessados END + '=,=' +
		CASE WHEN requerente IS NULL THEN '-' ELSE requerente END + '=,=' +
		CASE WHEN data_de_abertura IS NULL THEN '-' ELSE data_de_abertura END + '=,=' +
		CASE WHEN fase IS NULL THEN '-' ELSE fase END + '=,=' +
		CASE WHEN assunto IS NULL THEN '-' ELSE assunto END + '=,=' +
		CASE WHEN eletronico IS NULL THEN '-' ELSE CAST(eletronico AS VARCHAR) END + '=,=' +
		CASE WHEN observacoes IS NULL THEN '-' ELSE observacoes END + '=,=' +
		CASE WHEN processo_eletrônico IS NULL THEN '-' ELSE processo_eletrônico END + '=,=' +
		CASE WHEN data_de_autuação IS NULL THEN '-' ELSE data_de_autuação END + '=,=' +
		CASE WHEN tipo_do_processo IS NULL THEN '-' ELSE tipo_do_processo END + '=,=' +
	'=}'

	FROM RelatorioGeralKYCCVMPAD
	WHERE IdRequisicao = @IdRequisicao

	DECLARE @ProcessosPadBsm VARCHAR(MAX)
	SELECT @ProcessosPadBsm = COALESCE(@ProcessosPadBsm + ' ', '') +
	'{=' +
		CASE WHEN numero_pad IS NULL THEN '-' ELSE numero_pad END + '=,=' +
		CASE WHEN acusado IS NULL THEN '-' ELSE acusado END + '=,=' +
		CASE WHEN tipo_de_acusado IS NULL THEN '-' ELSE tipo_de_acusado END + '=,=' +
		CASE WHEN origem IS NULL THEN '-' ELSE origem END + '=,=' +
		CASE WHEN infracao IS NULL THEN '-' ELSE infracao END + '=,=' +
		CASE WHEN data_de_instauração IS NULL THEN '-' ELSE data_de_instauração END + '=,=' +
		CASE WHEN status IS NULL THEN '-' ELSE status END + '=,=' +
		CASE WHEN penalidade_aplicada IS NULL THEN '-' ELSE penalidade_aplicada END + '=,=' +
		CASE WHEN data_de_encerramento IS NULL THEN '-' ELSE data_de_encerramento END + '=,=' +
		CASE WHEN periodo_de_ocorrencia IS NULL THEN '-' ELSE periodo_de_ocorrencia END + '=,=' +
		CASE WHEN artigo_inciso IS NULL THEN '-' ELSE artigo_inciso END + '=,=' +
		CASE WHEN indice IS NULL THEN '-' ELSE CONVERT(varchar(max), indice) END + '=,=' +
		CASE WHEN valor IS NULL THEN '-' ELSE valor END + '=,=' +
		CASE WHEN relator_1_instancia IS NULL THEN '-' ELSE relator_1_instancia END + '=,=' +
		CASE WHEN conselheiro_2_1_instancia IS NULL THEN '-' ELSE conselheiro_2_1_instancia END + '=,=' +
		CASE WHEN conselheiro_3_1_instancia IS NULL THEN '-' ELSE conselheiro_3_1_instancia END + '=,=' +
		CASE WHEN relator_2_instancia IS NULL THEN '-' ELSE relator_2_instancia END + '=,=' +
		CASE WHEN proposta_tc IS NULL THEN '-' ELSE proposta_tc END + '=,=' +
		CASE WHEN valor_tc IS NULL THEN '-' ELSE valor_tc END + '=,=' +
		CASE WHEN decisao_cs IS NULL THEN '-' ELSE decisao_cs END +
	'=}'

	FROM RelatorioGeralKYCBSMPAD
	WHERE id_requisicao = @IdRequisicao

	DECLARE @ReceitaFederalPJ VARCHAR(MAX)
	SELECT @ReceitaFederalPJ = COALESCE(@ReceitaFederalPJ + ' ', '') +
	'{=' +
		CASE WHEN abertura IS NULL THEN '-' ELSE abertura END + '=,=' +
		CASE WHEN atividade_principal IS NULL THEN '-' ELSE atividade_principal END + '=,=' +
		CASE WHEN atividades_secundarias IS NULL THEN '-' ELSE atividades_secundarias END + '=,=' +
		CASE WHEN bairro IS NULL THEN '-' ELSE bairro END + '=,=' +
		CASE WHEN capital_social IS NULL THEN '-' ELSE capital_social END + '=,=' +
		CASE WHEN cep IS NULL THEN '-' ELSE cep END + '=,=' +
		CASE WHEN cnpj IS NULL THEN '-' ELSE cnpj END + '=,=' +
		CASE WHEN cnpjs_do_grupo IS NULL THEN '-' ELSE cnpjs_do_grupo END + '=,=' +
		CASE WHEN code IS NULL THEN '-' ELSE code END + '=,=' +
		CASE WHEN complemento IS NULL THEN '-' ELSE complemento END + '=,=' +
		CASE WHEN data_situacao IS NULL THEN '-' ELSE data_situacao END + '=,=' +
		CASE WHEN data_situacao_especial IS NULL THEN '-' ELSE data_situacao_especial END + '=,=' +
		CASE WHEN efr IS NULL THEN '-' ELSE efr END + '=,=' +
		CASE WHEN email IS NULL THEN '-' ELSE email END + '=,=' +
		CASE WHEN extra IS NULL THEN '-' ELSE extra END + '=,=' +
		CASE WHEN fantasia IS NULL THEN '-' ELSE fantasia END + '=,=' +
		CASE WHEN ibge IS NULL THEN '-' ELSE ibge END + '=,=' +
		CASE WHEN inscricao_municipal IS NULL THEN '-' ELSE inscricao_municipal END + '=,=' +
		CASE WHEN logradouro IS NULL THEN '-' ELSE logradouro END + '=,=' +
		CASE WHEN message IS NULL THEN '-' ELSE message END + '=,=' +
		CASE WHEN motivo_situacao IS NULL THEN '-' ELSE motivo_situacao END + '=,=' +
		CASE WHEN municipio IS NULL THEN '-' ELSE municipio END + '=,=' +
		CASE WHEN natureza_juridica IS NULL THEN '-' ELSE natureza_juridica END + '=,=' +
		CASE WHEN nome IS NULL THEN '-' ELSE nome END + '=,=' +
		CASE WHEN numero IS NULL THEN '-' ELSE numero END + '=,=' +
		CASE WHEN porte IS NULL THEN '-' ELSE porte END + '=,=' +
		CASE WHEN qsa IS NULL THEN '-' ELSE qsa END + '=,=' +
		CASE WHEN sigla_natureza_juridica IS NULL THEN '-' ELSE sigla_natureza_juridica END + '=,=' +
		CASE WHEN situacao IS NULL THEN '-' ELSE situacao END + '=,=' +
		CASE WHEN situacao_especial IS NULL THEN '-' ELSE situacao_especial END + '=,=' +
		CASE WHEN status IS NULL THEN '-' ELSE status END + '=,=' +
		CASE WHEN telefone IS NULL THEN '-' ELSE telefone END + '=,=' +
		CASE WHEN tipo IS NULL THEN '-' ELSE tipo END + '=,=' +
		CASE WHEN tipo_logradouro IS NULL THEN '-' ELSE tipo_logradouro END + '=,=' +
		CASE WHEN uf IS NULL THEN '-' ELSE uf END + '=,=' +
		CASE WHEN ultima_atualizacao IS NULL THEN '-' ELSE ultima_atualizacao END +
	'=}'

	FROM RelatorioGeralKYCRFBPJ
	WHERE id_requisicao = @IdRequisicao

	DECLARE @ReceitaFederalPF VARCHAR(MAX)
	SELECT @ReceitaFederalPF = COALESCE(@ReceitaFederalPF + ' ', '') +
	'{=' +
		CASE WHEN nome IS NULL THEN '-' ELSE nome END + '=,=' +
		CASE WHEN cpf IS NULL THEN '-' ELSE cpf END + '=,=' +
		CASE WHEN data_inscricao IS NULL THEN '-' ELSE data_inscricao END + '=,=' +
		CASE WHEN data_nascimento IS NULL THEN '-' ELSE data_nascimento END + '=,=' +
		CASE WHEN genero IS NULL THEN '-' ELSE genero END + '=,=' +
		CASE WHEN situacao_cadastral IS NULL THEN '-' ELSE situacao_cadastral END + '=,=' +
		CASE WHEN uf IS NULL THEN '-' ELSE uf END + '=,=' +
		CASE WHEN ano_obito IS NULL THEN '-' ELSE ano_obito END + '=,=' +
		CASE WHEN comprovante IS NULL THEN '-' ELSE comprovante END + '=,=' +
		CASE WHEN digito_verificador IS NULL THEN '-' ELSE digito_verificador END +
	'=}'

	FROM RelatorioGeralKYCRFBPF
	WHERE id_requisicao = @IdRequisicao


	SELECT

		Nome,
		CpfCnpj,
		FORMAT(DATEADD(HOUR, -3, DataHoraConsulta), 'dd/MM/yy hh:mm:ss') AS DataHoraConsulta,
		@Noticias AS Noticias,
		@Listas AS Listas,
		@ListasTerritorio AS ListasTerritorio,
		@ProcessosPas as ProcessosPas,
		@ProcessosPad as ProcessosPad,
		@ProcessosPadBsm as ProcessosPadBsm,
		@Processos AS Processos,
		@ReceitaFederalPJ as ReceitaFederalPJ,
		@ReceitaFederalPF AS ReceitaFederalPF,
		@NomesListas as NomesListas,
		@NomesListasTerritorio as NomesListasTerritorio


	FROM RelatorioGeralKYCAgendamento
	WHERE Id = @IdRequisicao

END