CREATE FUNCTION [dbo].[SumPgfnDebts]
(
    @Text NVARCHAR(1000)
)
RETURNS float
AS
BEGIN
    
	DECLARE @Sum FLOAT, @CharIndex INT
	SET @Sum = 0

	WHILE (LEN(LTRIM(@Text)) > 0)
	BEGIN
		SELECT @CharIndex = CHARINDEX('|', @Text, 0)

		SELECT @Sum = @Sum + SUBSTRING(@Text, 1, CASE WHEN @CharIndex > 1 THEN @CharIndex - 1 ELSE LEN(@Text) - 0 END)

		SELECT @Text = SUBSTRING(@Text, @CharIndex + 1, LEN(@Text))

		IF NOT (@CharIndex > 0) BREAK;
	END

	RETURN @Sum 
END