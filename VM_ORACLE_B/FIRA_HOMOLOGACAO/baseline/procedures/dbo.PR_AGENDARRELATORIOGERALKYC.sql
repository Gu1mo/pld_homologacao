CREATE PROCEDURE [dbo].[PR_AGENDARRELATORIOGERALKYC]
(
    @CPFCNPJ VARCHAR(20),
    @NOME NVARCHAR(2000),
    @ClientIdentity VARCHAR(2048),
    @Profissao NVARCHAR(2000),
    @DataNascimento NVARCHAR(100),
    @Pais NVARCHAR(2000),
    @Cidade NVARCHAR(2000),
    @DossiePrincipalID INT,
    @ProceedingsUUID NVARCHAR(2000)
)
AS
BEGIN

    DECLARE @IDENTITYOUTPUT TABLE ( ID INT )

    INSERT INTO RELATORIOGERALKYCAGENDAMENTO
    (
        CpfCnpj,
        Nome,
        DataHoraConsulta,
        Status,
        ClientIdentity,
        Classificacao,
        DataConclusao,
        Nascimento,
        Listas,
        Noticias,
        Processos,
        Rfb,
        Profissao,
        ProceedingsUUID,
        Pad,
        Pas,
        DossiePrincipalID,
        PadBSM
    )
    OUTPUT INSERTED.ID INTO @IDENTITYOUTPUT
    VALUES
    (
        @CPFCNPJ, 
        @NOME, 
        DATEADD(HOUR, -3, CAST(GETUTCDATE() AS DATETIME)), 
        0, 
        @ClientIdentity, 
        0, 
        NULL, 
        @DataNascimento, 
        1, 
        1, 
        1, 
        1, 
        @Profissao, 
        @ProceedingsUUID, 
        1, 
        1, 
        @DossiePrincipalID, 
        1
    )

    DECLARE @IDREQUISICAO INT
    SET @IDREQUISICAO = (SELECT ID FROM @IDENTITYOUTPUT)

	IF @Pais IS NOT NULL
	BEGIN
		CREATE TABLE #TEMPTABLERESULTADO (
			Territorio VARCHAR(1000),
			IdSublista INT
		);
		INSERT INTO #TEMPTABLERESULTADO (IdSublista, Territorio) EXEC PR_LISTA_ATENCAO_TERRITORIO_CONSULTA @Pais = @Pais, @Cidade = @Cidade;
		INSERT INTO RelatorioGeralKYCListasTerritorio (Territorio, IdSublista, IdRequisicao) SELECT Territorio, IdSublista, @IDREQUISICAO FROM #TEMPTABLERESULTADO;
	END

    -- If @Listas = 1
    -- BEGIN
        DECLARE @TEMPLISTAS TABLE (
          CPFCNPJ VARCHAR(20),
          NOME NVARCHAR(1000),
          LISTA NVARCHAR(300),
          FONTE NVARCHAR(100),
          CARGOEXERCIDO NVARCHAR(300),
          DETALHES NVARCHAR(4000),
          TERRITORIO NVARCHAR(200),
          DATAATUALIZACAO DATE,
          TOTLINHAS INT
        )

        INSERT INTO @TEMPLISTAS
              (CPFCNPJ, NOME, LISTA, FONTE, CARGOEXERCIDO, DETALHES, TERRITORIO, DATAATUALIZACAO, TOTLINHAS)
        EXEC PR_LISTAATENCAOCONSULTA @CPFCNPJ = @CPFCNPJ, @NOME = @NOME, @NOMEEXATO = 0, @IDUSUARIO = 1, @IDREQUISICAO = @IDREQUISICAO

        INSERT INTO RELATORIOGERALKYCLISTAS
              (CPFCNPJ, NOME, LISTA, FONTE, CARGOEXERCIDO, DETALHES, TERRITORIO, DATAATUALIZACAO, IDREQUISICAO)
        SELECT CPFCNPJ, NOME, LISTA, FONTE, CARGOEXERCIDO, DETALHES, TERRITORIO, DATAATUALIZACAO, @IDREQUISICAO FROM @TEMPLISTAS
    -- END

    INSERT INTO RelatorioGeralKYCStatusConsultas
	(id_requisicao,processos,noticias,pad,pas,rfb,listas,pad_bsm)
        VALUES (@IDREQUISICAO, 0, 0, 0, 0, 0, 0, 0)

    SELECT @IDREQUISICAO AS IDREQUISICAO

END