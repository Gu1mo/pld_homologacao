CREATE PROCEDURE [dbo].[PR_ATUALIZAR_SCORE]
(
    @id int, @name nvarchar(200), @category_id int, @value int
)
AS
BEGIN

--foi necessária essa alteração, pois quando deletava o score atrapalhava na gerar o Log do score na tabela SCORE_VALUE_VERSION. agora é feito UPDATE.

	--declare @id int = 10055
	--declare @name nvarchar(200) = 'Pessoas Relacionadas à PEPs (V)'
	--declare @category_id int = 2
	--declare @value int = 3

SET XACT_ABORT ON;

BEGIN TRY
  BEGIN TRAN;

  IF EXISTS (SELECT 1 FROM dbo.SCORE WITH (UPDLOCK, HOLDLOCK) WHERE id = @id)
  BEGIN
    UPDATE s
       SET s.[name]       = @name,
           s.category_id  = @category_id,
           s.[value]      = @value
     FROM dbo.SCORE s
    WHERE s.id = @id;
    -- Se a trigger estiver ativa, ela cuidará da SCORE_VALUE_VERSION quando [value] mudar
  END
  ELSE
  BEGIN
    -- Só usa IDENTITY_INSERT na ramificação de INSERT
    SET IDENTITY_INSERT dbo.SCORE ON;

    INSERT INTO dbo.SCORE (id, [name], category_id, [value])
    VALUES (@id, @name, @category_id, @value);

    SET IDENTITY_INSERT dbo.SCORE OFF;
  END

  COMMIT;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK;
  THROW;
END CATCH
END


--antigo
--BEGIN

--	declare @id int = 10055
--	declare @name nvarchar(200) = 'Pessoas Relacionadas à PEPs (V)'
--	declare @category_id int = 2
--	declare @value int = 3

--    declare @exists bit;
--	set @exists = (select count(1) from score c where c.id = @id and c.category_id = @category_id)
--	if @exists = 1 
--	begin
--		delete from score where id = @id and category_id = @category_id
--	end
--	SET IDENTITY_INSERT score ON
--	insert into score (id, [name], category_id, [value]) values(@id, @name, @category_id, @value)
--	SET IDENTITY_INSERT score OFF
--END

/*

delete score
dbcc checkident ('score',reseed,0)

insert into  score

		--cadastro
select 'Menores de 18 anos' as nome,		1 as category_id, 1 as [value] union all
select 'Maiores de 70 anos' as nome,		1 as category_id, 1 as [value] union all
select 'Profissão de risco' as nome,		1 as category_id, 1 as [value] union all
select 'Vinculado' as nome,					1 as category_id, 1 as [value] union all
select 'Tempo de relacionamento' as nome,	1 as category_id, 1 as [value] union all
select 'Canal de distribuição' as nome,		1 as category_id, 1 as [value] 

union all --listas
select CONCAT(b.nome,' (',c.Sigla,')') nome, 2 as category_id, 1 as [value]
from ListaAtencaoSublista b
inner join ListaAtencaoFonte c on b.IdFonte = c.id

union all --alertas
select b.nome nome, 2 as category_id, 3 as [value]
from RelatorioAlertas b

union all --produto
select 'Renda variável'			as nome, 4 as categor_id, 1 as [value] union all
select 'Renda fixa'				as nome, 4 as categor_id, 1 as [value] union all
select 'Derivativos'			as nome, 4 as categor_id, 1 as [value] union all
select 'Clubes de investimento'	as nome, 4 as categor_id, 1 as [value]


union all --background check
select 'Mídia negativa'				as nome, 5 as categor_id, 1 as [value] union all
select 'Processos judiciais'		as nome, 5 as categor_id, 1 as [value] union all
select 'Situação cadastral (RFB)'	as nome, 5 as categor_id, 1 as [value]
 
END*/