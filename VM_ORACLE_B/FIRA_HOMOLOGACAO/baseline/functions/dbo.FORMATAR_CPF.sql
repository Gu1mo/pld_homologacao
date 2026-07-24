CREATE FUNCTION [dbo].[FORMATAR_CPF](@cpf BIGINT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @cpfStr VARCHAR(20);
    SET @cpfStr = RIGHT('00000000000' + CAST(@cpf AS VARCHAR(20)), 11);
    RETURN SUBSTRING(@cpfStr, 1, 3) + '.' + SUBSTRING(@cpfStr, 4, 3) + '.' + SUBSTRING(@cpfStr, 7, 3) + '-' + RIGHT(@cpfStr, 2);
END;