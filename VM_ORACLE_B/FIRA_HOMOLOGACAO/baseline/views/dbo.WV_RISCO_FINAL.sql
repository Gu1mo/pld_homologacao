CREATE   VIEW [dbo].[WV_RISCO_FINAL]
AS

select DISTINCT 
 X.Data
,[Cód. do Cliente]
,[Nome do Cliente]
--,MAX(RISCO_TRANSA)RISCO_TRANSA
--,MAX(RISCO_CADASTRO)RISCO_CADASTRO
--,MAX(RISCO_PATRIMONIO)RISCO_PATRIMONIO
--,MAX(Risco_lista)Risco_lista


,CASE WHEN (max(x.RISCO_CADASTRO) = 'BAIXO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'BAIXO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'BAIXO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Baixo' 
	  WHEN (max(x.RISCO_CADASTRO) = 'BAIXO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'BAIXO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'MÉDIO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Médio' 
	  WHEN (max(x.RISCO_CADASTRO) = 'BAIXO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'MÉDIO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'BAIXO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Médio'
	  WHEN (max(x.RISCO_CADASTRO) = 'MÉDIO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'BAIXO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'BAIXO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Médio'
	  WHEN (max(x.RISCO_CADASTRO) = 'MÉDIO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'BAIXO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'MÉDIO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Médio'
	  WHEN (max(x.RISCO_CADASTRO) = 'MÉDIO' OR max(x.RISCO_CADASTRO) IS NULL) And (max(x.RISCO_PATRIMONIO) = 'MÉDIO' OR max(x.RISCO_PATRIMONIO) IS NULL) AND (max(x.RISCO_TRANSA) = 'MÉDIO' OR max(x.RISCO_TRANSA) IS NULL) AND (MAX(Risco_lista) <> 'ALTO' OR MAX(Risco_lista) IS NULL) THEN 'Médio'
ELSE 'Alto' END RISCO_FINAL
 


from (
select A.dt_periodo as Data,A.cd_cliente as [Cód. do Cliente],NM_cLIENTE AS [Nome do Cliente],b.titulo AS RISCO_TRANSA, null AS RISCO_CADASTRO, null AS RISCO_PATRIMONIO, null as Risco_lista
from  VDASH_ALERTAS A 
inner join score_levels b on a.ajuste = b.id
where tipo_alerta  = 'transacional'-- and DT_PERIODO = (select max(dt_periodo) from VDASH_ALERTAS)

	union all

select A.dt_periodo as Data,A.cd_cliente as [Cód. do Cliente],NM_cLIENTE AS [Nome do Cliente],null AS RISCO_TRANSA,b.titulo AS RISCO_CADASTRO,null AS RISCO_PATRIMONIO, null as Risco_lista
from VDASH_ALERTAS A 
inner join score_levels b on a.ajuste = b.id
where tipo_alerta  = 'cadastral'-- and DT_PERIODO = (select max(dt_periodo) from VDASH_ALERTAS)

	union all

select A.dt_periodo as Data,A.cd_cliente as [Cód. do Cliente],NM_cLIENTE AS [Nome do Cliente],null AS RISCO_TRANSA, null AS RISCO_CADASTRO, b.titulo AS RISCO_PATRIMONIO, null as Risco_lista
from  VDASH_ALERTAS A 
inner join score_levels b on a.ajuste = b.id
where tipo_alerta  = 'patrimonial'-- and DT_PERIODO =(select max(dt_periodo) from VDASH_ALERTAS)

	union all

select A.dt_periodo as Data,A.cd_cliente as [Cód. do Cliente],NM_cLIENTE AS [Nome do Cliente],null AS RISCO_TRANSA, null AS RISCO_CADASTRO,null as RISCO_PATRIMONIO,'Alto' AS Risco_lista
from  VDASH_ALERTAS A 
inner join score_levels b on a.ajuste = b.id
where tipo_alerta  = 'lista atencao' --and DT_PERIODO =(select max(dt_periodo) from VDASH_ALERTAS)
)x

--where x.[Cód. do Cliente] in (915777, 500212,179856)

group by x.Data,x.[Cód. do Cliente], [Nome do Cliente]