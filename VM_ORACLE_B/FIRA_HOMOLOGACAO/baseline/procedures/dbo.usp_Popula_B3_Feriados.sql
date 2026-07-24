/* =========================================================
   3) Procedure para popular feriados B3 (por faixa de anos)
   - Inclui: fixos + Carnaval (seg/ter), Sexta Santa, Corpus Christi
   - NÃO inclui 4ª de cinzas (tem pregão com horário especial)
   ========================================================= */
CREATE   PROCEDURE [dbo].[usp_Popula_B3_Feriados]
  @AnoIni int,
  @AnoFim int
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Anos AS (
    SELECT @AnoIni AS Ano
    UNION ALL
    SELECT Ano + 1 FROM Anos WHERE Ano < @AnoFim
  )
  INSERT INTO dbo.B3_FERIADOS (DT_FERIADO, DS_FERIADO)
  SELECT DT, DS
  FROM (
    -- Fixos
    SELECT DATEFROMPARTS(Ano,1,1)  AS DT, 'Confraternização Universal' AS DS FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,4,21), 'Tiradentes' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,5,1),  'Dia do Trabalho' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,9,7),  'Independência do Brasil' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,10,12),'Nossa Senhora Aparecida' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,11,2), 'Finados' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,11,15),'Proclamação da República' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,11,20),'Consciência Negra' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,12,24),'Véspera de Natal (sem sessão de negociação)' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,12,25),'Natal' FROM Anos
    UNION ALL SELECT DATEFROMPARTS(Ano,12,31),'Véspera de Ano Novo (sem sessão de negociação)' FROM Anos

    -- Móveis (base Páscoa)
    UNION ALL SELECT DATEADD(DAY,-48, dbo.fn_EasterSunday(Ano)), 'Carnaval' FROM Anos -- segunda
    UNION ALL SELECT DATEADD(DAY,-47, dbo.fn_EasterSunday(Ano)), 'Carnaval' FROM Anos -- terça
    UNION ALL SELECT DATEADD(DAY,-2,  dbo.fn_EasterSunday(Ano)), 'Sexta-feira Santa' FROM Anos
    UNION ALL SELECT DATEADD(DAY, 60, dbo.fn_EasterSunday(Ano)), 'Corpus Christi' FROM Anos
  ) X(DT, DS)
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.B3_FERIADOS F WHERE F.DT_FERIADO = X.DT
  )
  OPTION (MAXRECURSION 0);
END