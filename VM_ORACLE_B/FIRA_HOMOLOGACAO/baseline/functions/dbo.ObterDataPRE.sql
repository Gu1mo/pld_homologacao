CREATE FUNCTION [dbo].[ObterDataPRE](@DataReferencia DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @DT_PRE DATE;

    -- Calcula DT_PRE
    SELECT @DT_PRE = MIN(DT_PERIODO) FROM (
        SELECT TOP 10 DT_PERIODO 
        FROM ST_PERIODO 
        WHERE DT_PERIODO < @DataReferencia
        AND CD_DIASEMANA NOT IN (1,7) 
        AND DT_FERIADO = 'NAO' 
        ORDER BY DT_PERIODO DESC
    ) AS TabelaPRE;

    RETURN @DT_PRE;
END