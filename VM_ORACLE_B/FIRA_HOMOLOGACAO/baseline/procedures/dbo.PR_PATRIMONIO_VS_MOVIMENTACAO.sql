CREATE PROCEDURE [dbo].[PR_PATRIMONIO_VS_MOVIMENTACAO] @INICIO SMALLDATETIME, @FIM SMALLDATETIME, @CD_CLIENTE VARCHAR(50),@QTDPORPAGINA INT, @PAGINA INT  
WITH RECOMPILE  
AS   
  
  
--DECLARE @INICIO SMALLDATETIME, @FIM SMALLDATETIME, @CD_CLIENTE VARCHAR(50),@QTDPORPAGINA INT, @PAGINA INT  
--SET @CD_CLIENTE = ''  
--SET @INICIO ='20251201'  
--SET @FIM = '20251231'  
--SET @PAGINA =1  
--SET @QTDPORPAGINA = 100000  
 
  
  
---PATRIMONIO  
---busco o patrimonio do ultimo dia util do mes do alerta
--drop table if exists #PATRIMONIO
;with #PATRIMONIO as (
SELECT XX.CD_CLIENTE, isnull(CAST(SUM(VAL_BENS) AS NUMERIC(38,2)),0) PATRIMONIO
--INTO #PATRIMONIO
FROM ST_PATRIMONIO_LIQ  XX
WHERE DATA = (SELECT MAX(DATA) FROM ST_PATRIMONIO_LIQ YY 
				WHERE  (DATA) >= @INICIO
				AND  (DATA) <= @FIM
				and DATEPART(WEEKDAY, DATA) NOT IN (7,1)
				)
GROUP BY  XX.CD_CLIENTE
)

--CREATE NONCLUSTERED INDEX T1 ON [DBO].[#PATRIMONIO] ([CD_CLIENTE]) INCLUDE ([PATRIMONIO])         


--cadastro
--drop table if exists #v_cliente_todos
, #v_cliente_todos as (
select distinct IN_SITUAC,tp_situac,CD_CLIENTE,nm_cliente,INR,NM_ASSESSOR,TIPO
--into  #v_cliente_todos
from v_cliente_todos
)

                 
SELECT   
 convert(varchar,dt_referencia,103) AS [PERÍODO]  
,CASE WHEN C.IN_SITUAC = 'A' THEN 'ATIVO' ELSE 'INATIVO' END as [SITUAÇÃO MOD. BOLSA]    
,c.tp_situac [SITUAÇÃO CAD. GERAL]  
,A.CD_CLIENTE [CÓD. CLIENTE]  
,c.nm_cliente as [NOME DO CLIENTE]  
,C.INR   
,C.NM_ASSESSOR [NOME DO ASSESSOR]  
,C.TIPO [PF/PJ]  
,CD_HISTORICO [CÓD. HISTÓRICO]  
,DS_LANCAMENTO [LANÇAMENTO]    
,formaT(CAST(sum(VL_lancamento) AS NUMERIC(38,2)),'f','pt-br') [VL. LANÇAMENTO]  
  
,format((case when (select (CAST(sum(VL_lancamento) AS NUMERIC(38,2)))  
   from st_extrato_cc xx(NOLOCK)    
   where xx.cd_cliente = a.cd_cliente    
   and xx.dt_referencia = A.DT_REFERENCIA    
   and xx.CD_HISTORICO NOT IN (SELECT CD_PARAMETRO FROM st_cliente_parametros WHERE DS_PARAMETRO = 'DEPOSITO') ) is null then 0 else    
       (select (CAST(sum(VL_lancamento) AS NUMERIC(38,2)))   
       from st_extrato_cc xx (NOLOCK)   
       where xx.cd_cliente = a.cd_cliente    
       and xx.dt_referencia >= @INICIO and xx.DT_REFERENCIA <= @FIM    
       and xx.CD_HISTORICO  IN (SELECT CD_PARAMETRO FROM st_cliente_parametros WHERE DS_PARAMETRO = 'DEPOSITO')) end),'f','pt-br') [TOTAL MÊS]  
    
,format(isnull(B.Patrimonio,0),'f','pt-br') patrimonio  
    
,CASE WHEN A.CD_HISTORICO NOT IN (SELECT CD_PARAMETRO FROM st_cliente_parametros WHERE DS_PARAMETRO = 'DEPOSITO')   THEN '' --DEPÓSITO    
  WHEN (select (CAST(sum(VL_lancamento) AS NUMERIC(38,2))) from st_extrato_cc xx (NOLOCK)   
   where xx.cd_cliente = a.cd_cliente    
   and xx.dt_referencia >=@INICIO AND xx.dt_referencia <=@FIM    
   and xx.CD_HISTORICO  IN (SELECT CD_PARAMETRO FROM st_cliente_parametros WHERE DS_PARAMETRO = 'DEPOSITO') ) > isnull(B.Patrimonio,0) THEN 'Sim' else 'Não' end [ALERTA MENSAL]   
  
FROM ST_EXTRATO_CC A (NOLOCK)   
LEFT JOIN #PATRIMONIO B ON A.CD_CLIENTE = B.CD_CLIENTE   
LEFT JOIN #V_CLIENTE_TODOS C (NOLOCK) ON A.CD_CLIENTE = C.CD_CLIENTE
  
WHERE  A.CD_HISTORICO IN (SELECT CD_PARAMETRO FROM st_cliente_parametros WHERE DS_PARAMETRO = 'DEPOSITO') ---DEPOSITO/ENTRADA  
AND DT_REFERENCIA >= @INICIO AND DT_REFERENCIA <= @FIM  
AND A.CD_CLIENTE = CASE WHEN ISNULL(@CD_CLIENTE,'') ='' THEN A.CD_CLIENTE ELSE @CD_CLIENTE END  
  
GROUP BY   
C.IN_SITUAC,C.TP_SITUAC,C.INR,C.NM_ASSESSOR,C.TIPO ,DT_REFERENCIA ,A.CD_CLIENTE,C.NM_CLIENTE,CD_HISTORICO,DS_LANCAMENTO,isnull(B.Patrimonio,0)  
  
order by dt_referencia   
OFFSET (ISNULL(@PAGINA,1) - 1) * CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS  
FETCH NEXT CASE WHEN  ISNULL(@QTDPORPAGINA,'') = '' THEN 100000000 ELSE @QTDPORPAGINA END ROWS ONLY;