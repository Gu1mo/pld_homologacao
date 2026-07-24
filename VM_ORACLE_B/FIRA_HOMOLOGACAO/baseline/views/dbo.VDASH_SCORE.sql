CREATE VIEW [dbo].[VDASH_SCORE]   
AS    

/*
ESSA VIEW FOI CRIADA PARA ALIMENTAR A WV_RISCO_FINAL E ATENDER A SOLICITAÇÃO DO SAULO, QUANDO FOR ALTERADO O SCORE NO PORTAL, SERÁ ALTERADO NO PAINEL DE ALERTAS.
V_CADASTRO_DETALHE_CLIENTE retirada em 02/12/25 por Heitor e alerta ativo restrito add.
*/

SELECT 
XX.DT_PERIODO, XX.CD_CLIENTE, NM_CLIENTE, CD_CPFCGC, NM_ALERTA,   
SUM(QTD_ALERTAS_PERIODO) QTD_ALERTAS_PERIODO,inciso, 
ISNULL(MAX(sv_nome.value), 0) AS AJUSTE,Tipo_alerta
FROM (  
	  select  * from vdash_alertas
)XX     

/* ===== pega o valor vigente por NOME do alerta na data ===== */
OUTER APPLY (
  SELECT TOP (1) v.value
  FROM dbo.SCORE s
  JOIN dbo.SCORE_VALUE_VERSION v
    ON v.score_id = s.id
  WHERE UPPER(LTRIM(RTRIM(s.name))) COLLATE Latin1_General_CI_AI
        = UPPER(LTRIM(RTRIM(XX.NM_ALERTA))) COLLATE Latin1_General_CI_AI
    AND v.effective_from <= XX.DT_PERIODO
    AND (v.effective_to IS NULL OR v.effective_to > XX.DT_PERIODO)
  ORDER BY v.effective_from DESC
) sv_nome

GROUP BY XX.DT_PERIODO,XX.CD_CLIENTE, XX.NM_ALERTA,inciso, NM_CLIENTE, CD_CPFCGC,Tipo_alerta