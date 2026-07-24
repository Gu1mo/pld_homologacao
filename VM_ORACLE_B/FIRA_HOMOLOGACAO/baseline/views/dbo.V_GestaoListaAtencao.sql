CREATE VIEW [dbo].[V_GestaoListaAtencao]
--WITH ENCRYPTION
AS

SELECT        TOP (999999) s.Nome AS Lista,
{ fn CONCAT({ fn CONCAT({ fn CONCAT(f.Nome, ' (') }, f.Sigla) }, ')') } AS Fonte,
format(s.DataAtualizacaoDados,'d','pt-br')DataAtualizacaoDados ,
format(s.DataColetaDados,'d','pt-br') DataColetaDados,
p.Nome AS PeriodicidadeAtualizacao,
t.Nome AS Territorio
FROM            dbo.ListaAtencaoSublista AS s LEFT OUTER JOIN
                         dbo.ListaAtencaoFonte AS f ON f.Id = s.IdFonte LEFT OUTER JOIN
                         dbo.ListaAtencaoPeriodicidade AS p ON p.Id = s.IdPeriodicidade LEFT OUTER JOIN
                         dbo.ListaAtencaoTerritorioFonte AS t ON t.Id = f.IdTerritorio
WHERE s.Id != 19 AND s.Id != 32 AND s.Id != 33 AND s.Id != 34
ORDER BY Fonte, Lista