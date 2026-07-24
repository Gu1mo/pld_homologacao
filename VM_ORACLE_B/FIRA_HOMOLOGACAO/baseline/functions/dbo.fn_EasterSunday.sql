/* =========================================================
   2) Função Páscoa (para feriados móveis)
   ========================================================= */
CREATE   FUNCTION [dbo].[fn_EasterSunday](@Y int)
RETURNS date
AS
BEGIN
    -- Meeus/Jones/Butcher (calendário Gregoriano)
    DECLARE @a int, @b int, @c int, @d int, @e int, @f int, @g int,
            @h int, @i int, @k int, @l int, @m int, @month int, @day int;

    SET @a = @Y % 19;
    SET @b = @Y / 100;
    SET @c = @Y % 100;
    SET @d = @b / 4;
    SET @e = @b % 4;
    SET @f = (@b + 8) / 25;
    SET @g = (@b - @f + 1) / 3;
    SET @h = (19*@a + @b - @d - @g + 15) % 30;
    SET @i = @c / 4;
    SET @k = @c % 4;
    SET @l = (32 + 2*@e + 2*@i - @h - @k) % 7;
    SET @m = (@a + 11*@h + 22*@l) / 451;

    SET @month = (@h + @l - 7*@m + 114) / 31;
    SET @day   = ((@h + @l - 7*@m + 114) % 31) + 1;

    RETURN DATEFROMPARTS(@Y, @month, @day);
END