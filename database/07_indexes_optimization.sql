USE MotoFix;
GO

/* =====================================================================
   FASE 0 - Cargar datos de prueba masivos (3.000 documentos x 8 fragmentos)
   ===================================================================== */
SET NOCOUNT ON;

-- Limpieza por si se repite la prueba
DELETE crf FROM dbo.ConsultaRAGFragmento crf
  JOIN dbo.Fragmento f ON f.FragmentoId = crf.FragmentoId
  JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId
 WHERE d.Autor = N'BENCH';
DELETE FROM dbo.Documento WHERE Autor = N'BENCH';   -- borra tambien sus fragmentos (ON DELETE CASCADE)

-- Fragmentos reales con embedding, numerados, para reutilizarlos
CREATE TABLE #base
(
    rn              INT PRIMARY KEY,
    Texto           NVARCHAR(MAX),
    Embedding       VECTOR(1024),
    EmbeddingModelo NVARCHAR(100)
);

INSERT INTO #base (rn, Texto, Embedding, EmbeddingModelo)
SELECT ROW_NUMBER() OVER (ORDER BY FragmentoId), Texto, Embedding, EmbeddingModelo
FROM dbo.Fragmento
WHERE Embedding IS NOT NULL;

DECLARE @total INT = (SELECT COUNT(*) FROM #base);

-- 3.000 documentos de prueba (8 categorias, 3 tipos, 3 niveles repartidos de forma uniforme)
;WITH n AS
(
    SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Documento (CategoriaId, Titulo, Tipo, NivelAcceso, Autor, Activo)
SELECT ((i - 1) % 8) + 1,
       CONCAT(N'BENCH documento ', i),
       CHOOSE(((i - 1) % 3) + 1, N'Incidencia', N'Guia', N'FAQ'),
       ((i - 1) % 3) + 1,
       N'BENCH',
       CASE WHEN i % 20 = 0 THEN 0 ELSE 1 END       -- 5 % inactivos
FROM n;

-- 8 fragmentos por documento de prueba, con embeddings copiados de los reales
INSERT INTO dbo.Fragmento (DocumentoId, Orden, Texto, NivelAcceso, Embedding, EmbeddingModelo, EmbeddingFecha)
SELECT d.DocumentoId, j.j + 1, b.Texto, d.NivelAcceso, b.Embedding, b.EmbeddingModelo, SYSDATETIME()
FROM dbo.Documento d
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS j (j)
CROSS APPLY (SELECT Texto, Embedding, EmbeddingModelo FROM #base
             WHERE rn = ((d.DocumentoId * 7 + j.j) % @total) + 1) AS b
WHERE d.Autor = N'BENCH';

DROP TABLE #base;

SELECT COUNT(*) AS FragmentosTotales FROM dbo.Fragmento;     -- ~24.042
GO

/* =====================================================================
   FASE 1 - MEDICION "ANTES"  (sin indices de apoyo, version 1 del procedimiento)
   Resultado esperado: Clustered Index Scan sobre Fragmento (24.000 filas,
   cada una con un vector de 4 KB) + Hash Match. Muchas logical reads.
   ===================================================================== */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DBCC DROPCLEANBUFFERS;   -- cache fria (solo en desarrollo)
GO

DECLARE @qv VECTOR(1024) = (SELECT Embedding FROM dbo.Fragmento WHERE FragmentoId = 5);  -- vector de ejemplo

EXEC dbo.usp_BuscarFragmentosPorVector @qv = @qv, @K = 5, @CategoriaId = 2, @Tipo = N'Guia';
GO

/* =====================================================================
   FASE 2 - OPTIMIZACION 1: indices
     a) Filtrado + compuesto sobre Documento: solo documentos activos, por (Categoria, Tipo)
     b) Unico + compuesto sobre Fragmento por (DocumentoId, Orden): permite localizar
        los fragmentos de un documento con Index Seek en lugar de recorrer toda la tabla
   NOTA: la columna VECTOR no puede ser clave de un indice B-tree; el motor accede a
   ella mediante Key Lookup solo para los fragmentos que superan el filtro.
   ===================================================================== */
CREATE NONCLUSTERED INDEX IX_Documento_Cat_Tipo_Activos
    ON dbo.Documento (CategoriaId, Tipo)
    INCLUDE (Titulo)
    WHERE Activo = 1;

CREATE UNIQUE NONCLUSTERED INDEX UX_Fragmento_Doc_Orden
    ON dbo.Fragmento (DocumentoId, Orden)
    INCLUDE (NivelAcceso);
GO

/* FASE 2b - MEDICION "DESPUES DE LOS INDICES" (mismo procedimiento v1) */
DBCC DROPCLEANBUFFERS;
GO
DECLARE @qv VECTOR(1024) = (SELECT Embedding FROM dbo.Fragmento WHERE FragmentoId = 5);

EXEC dbo.usp_BuscarFragmentosPorVector @qv = @qv, @K = 5, @CategoriaId = 2, @Tipo = N'Guia';
GO

/* =====================================================================
   FASE 3 - OPTIMIZACION 2: reescritura de la consulta
   El patron  (@param IS NULL OR columna = @param)  hace que el optimizador
   cachee UN plan valido para cualquier combinacion de parametros, y por eso
   no puede usar un Index Seek sobre el filtro. OPTION (RECOMPILE) permite
   simplificar la condicion con los valores reales de cada llamada.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.usp_BuscarFragmentosPorVector
    @qv          VECTOR(1024),
    @K           INT           = 5,
    @CategoriaId INT           = NULL,
    @Tipo        NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@K)
           f.FragmentoId,
           d.DocumentoId,
           d.Titulo,
           d.Tipo,
           c.Nombre AS Categoria,
           f.Orden,
           f.Texto,
           VECTOR_DISTANCE('cosine', @qv, f.Embedding) AS Distancia
    FROM   dbo.Fragmento AS f
    JOIN   dbo.Documento AS d ON d.DocumentoId = f.DocumentoId
    JOIN   dbo.Categoria AS c ON c.CategoriaId = d.CategoriaId
    WHERE  d.Activo = 1
      AND  f.Embedding IS NOT NULL
      AND  (@CategoriaId IS NULL OR d.CategoriaId = @CategoriaId)
      AND  (@Tipo        IS NULL OR d.Tipo        = @Tipo)
    ORDER BY Distancia ASC
    OPTION (RECOMPILE);
END;
GO

/* FASE 3b - MEDICION "DESPUES DE INDICES + RECOMPILE" */
DBCC DROPCLEANBUFFERS;
GO
DECLARE @qv VECTOR(1024) = (SELECT Embedding FROM dbo.Fragmento WHERE FragmentoId = 5);

EXEC dbo.usp_BuscarFragmentosPorVector @qv = @qv, @K = 5, @CategoriaId = 2, @Tipo = N'Guia';
GO

/* Caso sin filtros (busqueda sobre toda la base): aqui el indice NO ayuda, porque hay
   que calcular la distancia contra todos los vectores (kNN exacto = recorrido completo).
   Es el limite natural de VECTOR_DISTANCE; para volumenes grandes se usaria un indice
   vectorial aproximado (CREATE VECTOR INDEX + VECTOR_SEARCH, preview en SQL Server 2025). */
DBCC DROPCLEANBUFFERS;
GO
DECLARE @qv VECTOR(1024) = (SELECT Embedding FROM dbo.Fragmento WHERE FragmentoId = 5);

EXEC dbo.usp_BuscarFragmentosPorVector @qv = @qv, @K = 5;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* =====================================================================
   FASE 4 - LIMPIEZA: borrar los datos de prueba (los indices se quedan)
   ===================================================================== */
DELETE crf FROM dbo.ConsultaRAGFragmento crf
  JOIN dbo.Fragmento f ON f.FragmentoId = crf.FragmentoId
  JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId
 WHERE d.Autor = N'BENCH';
DELETE FROM dbo.Documento WHERE Autor = N'BENCH';
GO

SELECT COUNT(*) AS Documentos FROM dbo.Documento;     -- debe volver a 17
SELECT COUNT(*) AS Fragmentos FROM dbo.Fragmento;     -- debe volver a 42
GO
