CREATE PROCEDURE [dbo].[FIRA_PR_CARGA_ST_CORRETAGEM_ORDEM] @PREGAO DATETIME, @PREGAOFIM DATETIME  
--WITH ENCRYPTION  
AS  
  
DROP TABLE IF EXISTS [dbo].[ST_CORRETAGEM_ORDEM_PADRAO]
    CREATE TABLE [dbo].[ST_CORRETAGEM_ORDEM_PADRAO] (
    [VL_CORTOT] float NULL,
    [VL_TOTNEG] float NULL,
    [VL_CORTOT_ORI] float NULL,
    [DESCONTO] float NULL,
    [CORRETAGEM_INICIAL] float NULL,
    [PERCENTUAL_DESCONTO] float NULL,
    [ISS] float NULL,
    [VL_CORRESP] float NULL,
    [VL_IRCORR] float NULL,
    [VL_EMOLUM] float NULL,
    [VL_EMOLUM_BV] float NULL,
    [VL_EMOLUM_CB] float NULL,
    [CD_CLIENTE] int NULL,
    [CD_ASSESSOR] int NULL,
    [DT_NEGOCIO] smalldatetime NULL,
    [CD_NATOPE] char(1) NULL,
    [TP_MERCADO] varchar(10) NULL,
    [CD_CONTRAPARTE] numeric(5,0) NULL,
    [TP_NEGOCIO] varchar(3) NULL,
    [CD_PAPEL] varchar(12) NULL,
    [NR_NEGOCIO] int NULL,
    [HH_NEGOCIO] varchar(5) NULL,
    [DT_DATORD] smalldatetime NULL,
    [NR_SEQORD] int NULL,
    [NR_SUBSEQ] int NULL,
    [DV_NEGOCIO] int NULL,
    [QT_DIVISOR] float NULL,
    [QT_MULTIPLICADOR] float NULL,
    [VL_NEGOCIO] float NULL,
    [VL_TAXANA] float NULL,
    [VL_VALDES] float NULL,
    [VL_COMASS] float NULL,
    [VL_AGENTE] float NULL,
    [VL_TAXREG] float NULL,
    [VL_TAXREG_BV] float NULL,
    [VL_TAXREG_CB] float NULL,
    [VL_ENCARGOS] float NULL,
    [VL_BASEIRDT] float NULL,
    [VL_IRRETIDO] float NULL,
    [VL_IRRF_DESPESA] float NULL,
    [VL_ISS_CORRESP] float NULL,
    [VL_LIQOPER] float NULL,
    [VL_IROPER] float NULL,
    [CD_SISTEMA_ORIGEM] int NULL,
    [FT_VALORIZACAO] float NULL,
    [NR_SEQCOMI] int NULL,
    [CD_BOLSAMOV] char(1) NULL,
    [CD_CLIENTE_BRO] int NULL,
    [DT_SISTEMA] varchar(20) NULL,
    [IN_AFTERM] varchar(50) NULL,
    [CD_OPERADOR] int NULL,
    [IN_LEILAO] varchar(5) NULL,
    [TP_VCOTER] numeric(5,0) NULL,
	[DT_FIRA] DATETIME NULL,
	[NR_OFEMEGA] BIGINT NULL
); 
 

/***************************************************
inicio da comparação entre a tabela
da base padrao fira origem x tabela cliente destino
*****************************************************/
EXEC dbo.usp_sync_table_schema_add_alter_2012
  --@src_schema='dbo',, @src_table='ST_CORRETAGEM_ORDEM_PADRAO',
  @schema_name='dbo', @base_table='ST_CORRETAGEM_ORDEM',
  @execute=1,
  @allow_drop=1, @apply_rename_map=1;


--DECLARE @PREGAO DATETIME,@PREGAOFIM DATETIME  
--SET @PREGAO ='20230601'  
--SET @PREGAOFIM ='20230621'  
  
/***************************   
 CARGA CORRETAGEM ORDEM    
*****************************/  
  
WHILE @PREGAO < @PREGAOFIM  
BEGIN   


 ----DELETE TABLE  
 DELETE FROM ST_CORRETAGEM_ORDEM WHERE DT_NEGOCIO = @PREGAO  
  
  
 /*#########################*/  
 --#######  INSERT  #######--  
 /*#########################*/  
 
 
INSERT INTO ST_CORRETAGEM_ORDEM
(
VL_CORTOT,VL_TOTNEG,VL_CORTOT_ORI,CD_CLIENTE,CD_ASSESSOR,DT_NEGOCIO,CD_NATOPE,TP_MERCADO,CD_CONTRAPARTE,TP_NEGOCIO,CD_PAPEL,NR_NEGOCIO,HH_NEGOCIO,
DT_DATORD,NR_SEQORD,NR_SUBSEQ,QT_DIVISOR,QT_MULTIPLICADOR,VL_NEGOCIO,CD_SISTEMA_ORIGEM,FT_VALORIZACAO,NR_SEQCOMI,CD_BOLSAMOV,CD_CLIENTE_BRO,
DT_SISTEMA,IN_AFTERM,IN_LEILAO, H.TP_VCOTER,NR_OFEMEGA
)
Select 
SUM(m.VL_CORTOT) vl_cortot ,SUM(m.VL_TOTNEG) vl_totneg ,sum(m.VL_CORTOT_ORI) VL_CORTOT_ORI,m.cd_cliente,m.cd_assessor,m.dt_negocio dt_negocio,
m.cd_natope,h.tp_mercado,h.cd_contraparte,a.tp_negocio,h.cd_negocio AS CD_PAPEL,m.NR_NEGOCIO,h.Hh_Negocio,DT_DATORD,NR_SEQORD,NR_SUBSEQ,
m.qt_qtdesp qt_qtdespDivisor,a.qt_qtdesp qt_qtdespMultiplicador

,CASE WHEN h.FT_VALORIZACAO = 1 THEN SUM(m.vl_negocio) ELSE (SUM(m.vl_negocio) / NULLIF(h.FT_VALORIZACAO,1)) END AS  vl_negocio

,h.cd_opera_mega,h.FT_VALORIZACAO,ISNULL(a.NR_SEQCOMI,0) NRSEQCOMI,
m.cd_bolsamov,m.CD_CLIENTE_BRO,H.DT_SISTEMA,H.IN_AFTERM,h.IN_LEILAO, H.TP_VCOTER,H.NR_OFEMEGA

from 
ST_TORCOM a,ST_TORNEG H,ST_v_tbomovcl m

where 
    m.cd_cliente_fin >=0
and m.in_corresp = 'N'
AND A.DT_NEGOCIO = H.DT_PREGAO
AND A.CD_BOLSAMOV = H.CD_BOLSAMOV
AND A.CD_NEGOCIO = H.CD_NEGOCIO
AND A.NR_NEGOCIO = H.NR_NEGOCIO
AND A.CD_NATOPE = H.CD_NATOPE
and m.dt_negocio = a.dt_negocio
and m.cd_bolsamov = a.cd_bolsamov
and m.cd_cliente = a.cd_cliente
and m.cd_cliente_bro = a.cd_cliente_bro
and m.cd_cliente_fin = a.cd_cliente_fin
and m.nr_negocio = a.nr_negocio
and m.cd_negocio = a.cd_negocio
and m.cd_natope = a.cd_natope
and m.cd_carliq = a.cd_carliq
and m.in_liquida = ISNULL(a.in_liquida, ' ')
and m.in_broker = 'F'
and m.tp_negocio = a.tp_negocio
and a.dt_datord IS NOT NULL
and m.DT_NEGOCIO = @PREGAO

group by 
m.cd_cliente,m.cd_assessor,m.dt_negocio ,
m.cd_natope,h.tp_mercado,h.cd_contraparte,a.tp_negocio,h.cd_negocio,m.NR_NEGOCIO,h.Hh_Negocio,DT_DATORD,NR_SEQORD,NR_SUBSEQ,
m.qt_qtdesp,a.qt_qtdesp,h.cd_opera_mega,h.FT_VALORIZACAO,ISNULL(a.NR_SEQCOMI,0),m.cd_bolsamov,m.CD_CLIENTE_BRO,
H.DT_SISTEMA,H.IN_AFTERM,h.IN_LEILAO, H.TP_VCOTER,H.NR_OFEMEGA
   


  
   
 /*#########################*/  
 --#    UPDATES    #--  
 /*#########################*/  
 
 --ATUALIZA O CD_OPERADOR  
 UPDATE ST_CORRETAGEM_ORDEM  
 SET CD_OPERADOR =  (SELECT TOP 1 CD_CODUSU   
      FROM ST_OPER_ORDENS X   
      WHERE X.DT_DATORD = ST_CORRETAGEM_ORDEM.DT_NEGOCIO  
      AND  CD_CLIENTE = ST_CORRETAGEM_ORDEM.CD_CLIENTE  
      AND CD_NEGOCIO = ST_CORRETAGEM_ORDEM.CD_PAPEL  
      AND NR_SEQORD = ST_CORRETAGEM_ORDEM.NR_SEQORD  
      AND CD_NATOPE = ST_CORRETAGEM_ORDEM.CD_NATOPE  
      )  
 WHERE CD_OPERADOR IS NULL  
 AND DT_NEGOCIO = @PREGAO  
  
 
 SET @PREGAO  = @PREGAO + 1  
END

-- ================================================
-- Marca DT_FIRA para registros carregados (fallback)
-- ================================================
DECLARE @__dt_fira_now DATETIME = GETDATE();
IF COL_LENGTH(N'dbo.ST_CORRETAGEM_ORDEM', 'DT_FIRA') IS NOT NULL
BEGIN
    UPDATE [dbo].[ST_CORRETAGEM_ORDEM]
    SET DT_FIRA = @__dt_fira_now
    WHERE DT_FIRA IS NULL;
END

/******* fim do processo de carga **********/

--passo 3
/***** limpa a tabela do banco para nao ficar sujeira ******/
DROP TABLE IF EXISTS ST_CORRETAGEM_ORDEM_PADRAO