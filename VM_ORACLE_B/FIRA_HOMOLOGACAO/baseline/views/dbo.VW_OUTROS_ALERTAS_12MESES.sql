CREATE VIEW [dbo].[VW_OUTROS_ALERTAS_12MESES]
--WITH ENCRYPTION
AS

SELECT TOP 100 PERCENT
       ALERTA,
       SUM(QTD) AS QTD_ULT_12_MES
FROM   (SELECT   nm_alerta AS ALERTA,
                   COUNT(CD_CLIENTE) AS QTD,
                   dt_periodo AS DATA
        FROM     vdash_alertas
        GROUP BY dt_periodo, nm_alerta
        ) AS X
WHERE  DATA BETWEEN DATEADD(MONTH, -12, GETDATE()) AND GETDATE()
       
GROUP BY ALERTA
ORDER BY QTD_ULT_12_MES DESC;