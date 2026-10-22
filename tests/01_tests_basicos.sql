USE MotoFix;
GO
REVERT; 
GO

SELECT (SELECT COUNT(*) FROM dbo.Categoria)       AS Categorias,
       (SELECT COUNT(*) FROM dbo.ModeloMoto)      AS Modelos,
       (SELECT COUNT(*) FROM dbo.Documento)       AS Documentos,
       (SELECT COUNT(*) FROM dbo.DocumentoModelo) AS DocModelo,
       (SELECT COUNT(*) FROM dbo.Fragmento)       AS Fragmentos;
GO

SELECT COUNT(*) AS Total,
       SUM(CASE WHEN Embedding IS NOT NULL THEN 1 ELSE 0 END) AS ConEmbedding,
       MIN(VECTORPROPERTY(Embedding, 'Dimensions'))           AS DimensionMin,
       MAX(VECTORPROPERTY(Embedding, 'Dimensions'))           AS DimensionMax
FROM dbo.Fragmento;
GO

DECLARE @r TABLE (Prueba NVARCHAR(60), Error INT, Mensaje NVARCHAR(300));

BEGIN TRY
    INSERT INTO dbo.Documento (CategoriaId, Titulo, Tipo, NivelAcceso, Autor) VALUES (1, N'T3a', N'Tipo raro', 1, N'x');
END TRY
BEGIN CATCH INSERT @r VALUES (N'CHECK tipo invalido', ERROR_NUMBER(), LEFT(ERROR_MESSAGE(), 300)); END CATCH;

BEGIN TRY
    INSERT INTO dbo.Documento (CategoriaId, Titulo, Tipo, NivelAcceso, Autor) VALUES (1, N'T3b', N'FAQ', 9, N'x');
END TRY
BEGIN CATCH INSERT @r VALUES (N'CHECK nivel fuera de rango', ERROR_NUMBER(), LEFT(ERROR_MESSAGE(), 300)); END CATCH;

BEGIN TRY
    INSERT INTO dbo.Documento (CategoriaId, Titulo, Tipo, NivelAcceso, Autor)
    SELECT TOP (1) CategoriaId, Titulo, Tipo, NivelAcceso, Autor FROM dbo.Documento;
END TRY
BEGIN CATCH INSERT @r VALUES (N'UNIQUE titulo duplicado', ERROR_NUMBER(), LEFT(ERROR_MESSAGE(), 300)); END CATCH;

BEGIN TRY
    INSERT INTO dbo.Documento (CategoriaId, Titulo, Tipo, NivelAcceso, Autor) VALUES (999, N'T3d', N'FAQ', 1, N'x');
END TRY
BEGIN CATCH INSERT @r VALUES (N'FK categoria inexistente', ERROR_NUMBER(), LEFT(ERROR_MESSAGE(), 300)); END CATCH;

SELECT * FROM @r;
GO

BEGIN TRAN;
    SELECT 'ANTES' AS Momento, NivelAcceso FROM dbo.Fragmento WHERE DocumentoId = 5;
    UPDATE dbo.Documento SET NivelAcceso = 3 WHERE DocumentoId = 5;
    SELECT 'DURANTE' AS Momento, f.NivelAcceso, d.FechaModificacion
    FROM dbo.Fragmento f JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId WHERE f.DocumentoId = 5;
ROLLBACK;
GO

BEGIN TRAN;
    SELECT 'ANTES' AS Momento, CASE WHEN Embedding IS NULL THEN 0 ELSE 1 END AS TieneEmbedding FROM dbo.Fragmento WHERE FragmentoId = 1;
    UPDATE dbo.Fragmento SET Texto = Texto + N' (texto modificado)' WHERE FragmentoId = 1;
    SELECT 'DESPUES' AS Momento, CASE WHEN Embedding IS NULL THEN 0 ELSE 1 END AS TieneEmbedding FROM dbo.Fragmento WHERE FragmentoId = 1;
    SELECT * FROM dbo.vw_FragmentoPendiente;
ROLLBACK;
GO

SELECT TOP (5) * FROM dbo.vw_DocumentoResumen ORDER BY DocumentoId;
SELECT * FROM dbo.fn_DocumentosPorModelo(5);
SELECT dbo.fn_Extracto(Texto, 80) AS Extracto FROM dbo.Fragmento WHERE FragmentoId = 1;
GO
