CREATE FUNCTION [dbo].[ObterDataPOS](@DataReferencia DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @DT_POS DATE;

    -- Calcula DT_POS
    SELECT @DT_POS = MAX(DT_PERIODO) FROM (
        SELECT TOP 10 DT_PERIODO 
        FROM ST_PERIODO 
        WHERE DT_PERIODO >= @DataReferencia
        AND CD_DIASEMANA NOT IN (1,7) 
        AND DT_FERIADO = 'NAO' 
        ORDER BY DT_PERIODO ASC
    ) AS TabelaPOS;

    RETURN @DT_POS;
END