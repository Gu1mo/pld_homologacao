CREATE VIEW [dbo].[VW_OUTROS_ALERTAS]
--WITH ENCRYPTION
AS
SELECT		ALERTA,
               QTD,
               DATA
			   	  


FROM     (SELECT   nm_alerta AS ALERTA,
                   COUNT(CD_CLIENTE) AS QTD,
                   dt_periodo as DATA
          FROM     vdash_alertas
          GROUP BY dt_periodo,nm_alerta          
		  ) AS X