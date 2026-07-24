CREATE TABLE [dbo].[ST_DIRETAS_BMF] (
    [CD_CLIENTE_COMPRA] int NULL,
    [NM_CLIENTE_COMPRA] varchar(400) NULL,
    [VINC_COMPRA] char(1) NULL,
    [CD_CLIENTE_VENDA] int NULL,
    [NM_CLIENTE_VENDA] varchar(400) NULL,
    [VINC_VENDA] char(1) NULL,
    [DT_NEGOCIO] datetime NULL,
    [NR_NEGOCIO] numeric(12,0) NULL,
    [QT_NEGOCIO_COMPRA] float NOT NULL,
    [QT_NEGOCIO_VENDA] float NOT NULL,
    [CD_NEGOCIO] varchar(20) NULL,
    [CD_COMMOD] char(3) NULL,
    [CD_SERIE] char(4) NULL,
    [HH_COMPRA] varchar(8) NULL,
    [HH_VENDA] varchar(8) NULL,
    [VL_TOTNEG_COMPRA] float NOT NULL,
    [VL_TOTNEG_VENDA] float NOT NULL,
    [VL_NEGOCIO_COMPRA] float NOT NULL,
    [VL_NEGOCIO_VENDA] float NOT NULL,
    [CD_ASSESSOR_COMPRA] int NULL,
    [DS_ASSESSOR_COMPRA] varchar(60) NULL,
    [CD_ASSESSOR_VENDA] int NULL,
    [DS_ASSESSOR_VENDA] varchar(60) NULL,
    [SISTEMA_COMPRA] varchar(10) NULL,
    [USUARIO_COMPRA] varchar(100) NULL,
    [SISTEMA_VENDA] varchar(10) NULL,
    [USUARIO_VENDA] varchar(100) NULL,
    [tp_cliente_compra] int NULL,
    [tp_cliente_venda] int NULL,
    [DS_MERCAD] varchar(100) NULL,
    [in_after] char(1) NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate())
);

CREATE INDEX [ID001_ST_DIRETAS_BMF] ON [dbo].[ST_DIRETAS_BMF] ([DT_NEGOCIO]);

CREATE INDEX [ID002_ST_DIRETAS_BMF] ON [dbo].[ST_DIRETAS_BMF] ([DT_NEGOCIO]);