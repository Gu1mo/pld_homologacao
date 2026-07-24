CREATE FUNCTION [dbo].[FORMATAR_CNPJ](@cnpj BIGINT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @cnpjStr VARCHAR(20);
	set @cnpj = substring(cast(@cnpj as varchar),1,14)
    SET @cnpjStr = RIGHT('00000000000000' + CAST(@cnpj AS VARCHAR(20)), 14);
    RETURN SUBSTRING(@cnpjStr, 1, 2) + '.' + SUBSTRING(@cnpjStr, 3, 3) + '.' + SUBSTRING(@cnpjStr, 6, 3) + '/' + SUBSTRING(@cnpjStr, 9, 4) + '-' + RIGHT(@cnpjStr, 2);
END;