CREATE FUNCTION [dbo].[RemoverDiacriticos](
    @Nome nvarchar(500)
)
RETURNS nvarchar(500)
AS
BEGIN

SELECT @Nome = UPPER(@Nome)

SELECT @Nome = 
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Nome, 
	'Á', 'A'), 'À', 'A'), 'Â', 'A'), 'Ã', 'A'), 'É', 'E'), 'È', 'E'), 'Ê', 'E'),
	'Í', 'I'), 'Ì', 'I'), 'Î', 'I'), 'Ó', 'O'), 'Ò', 'O'), 'Ô', 'O'), 'Õ', 'O'),
	'Ú', 'U'), 'Ù', 'U'), 'Û', 'U'), 'Ü', 'U'), 'Ç', 'C'), 'Ñ', 'N')

return @Nome

END