CREATE TABLE [dbo].[Subcategoria] (
    [ID] int IDENTITY(1,1) NOT NULL,
    [INDICE] int NOT NULL,
    [NOME] nvarchar(1000) NOT NULL,
    [IDCATEGORIA] int NOT NULL,
    [DT_FIRA] datetime NULL DEFAULT (getdate()),
    CONSTRAINT [PK_Subcategoria] PRIMARY KEY ([ID])
);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_001] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_002] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_003] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_004] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_005] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_006] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_007] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_008] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_009] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_010] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_011] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_012] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_013] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_014] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_015] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_016] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_017] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_018] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_019] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_020] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_021] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_022] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_023] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_024] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_025] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_026] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_027] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_028] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_029] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_031] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_041] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_042] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_043] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_044] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_045] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_046] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_047] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_048] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_049] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_050] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_061] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_062] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_063] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_064] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_065] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_066] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_067] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_068] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_069] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_070] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_071] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_072] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_073] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_074] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_075] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_076] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_077] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_078] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_079] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_080] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_081] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_082] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_083] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_084] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_085] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_086] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_087] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_088] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_089] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_090] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_091] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_092] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_093] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_094] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_095] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_096] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_097] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_098] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_099] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_100] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_101] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_102] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_103] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);

ALTER TABLE [dbo].[Subcategoria] ADD CONSTRAINT [FK_Subcatego_IDCAT_104] FOREIGN KEY ([IDCATEGORIA]) REFERENCES [dbo].[Categoria] ([ID]);