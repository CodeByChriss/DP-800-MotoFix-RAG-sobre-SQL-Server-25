USE MotoFix;
GO

/* A1. CTE + funciones de ventana: los 2 documentos con mas contenido de cada categoria
       y que porcentaje del texto de su categoria representan. */
;WITH Resumen AS
(
    SELECT c.Nombre AS Categoria, d.DocumentoId, d.Titulo,
           COUNT(f.FragmentoId)  AS NumFragmentos,
           SUM(LEN(f.Texto))     AS Caracteres
    FROM dbo.Documento d
    JOIN dbo.Categoria c ON c.CategoriaId = d.CategoriaId
    LEFT JOIN dbo.Fragmento f ON f.DocumentoId = d.DocumentoId
    GROUP BY c.Nombre, d.DocumentoId, d.Titulo
),
Ranking AS
(
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Categoria ORDER BY Caracteres DESC) AS Posicion,
           SUM(Caracteres) OVER (PARTITION BY Categoria)                        AS TotalCategoria
    FROM Resumen
)
SELECT Categoria, Titulo, NumFragmentos, Caracteres, Posicion,
       CAST(100.0 * Caracteres / TotalCategoria AS DECIMAL(5,1)) AS PctDeLaCategoria
FROM Ranking
WHERE Posicion <= 2
ORDER BY Categoria, Posicion;
GO

/* A2. JSON: catalogo de documentos de una categoria con sus modelos, como documento JSON anidado */
SELECT d.DocumentoId AS id,
       d.Titulo      AS titulo,
       d.Tipo        AS tipo,
       (SELECT CONCAT(m.Marca, N' ', m.Modelo) AS modelo
          FROM dbo.DocumentoModelo dm
          JOIN dbo.ModeloMoto m ON m.ModeloId = dm.ModeloId
         WHERE dm.DocumentoId = d.DocumentoId
         FOR JSON PATH) AS modelos
FROM dbo.Documento d
WHERE d.CategoriaId = 1
FOR JSON PATH, ROOT('documentos');
GO

/* A3. Expresiones regulares (REGEXP_LIKE, requiere compatibilidad 170):
       fragmentos que mencionan un codigo de error numerico, p. ej. "Error 18456" */
SELECT f.FragmentoId, d.Titulo, dbo.fn_Extracto(f.Texto, 90) AS Extracto
FROM dbo.Fragmento f
JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId
WHERE REGEXP_LIKE(f.Texto, N'[Ee]rror\s+[0-9]{4,5}');
GO

/* A4. REGEXP_SUBSTR: extraer las presiones de neumaticos (formato "2,2 bar") de los textos */
SELECT f.FragmentoId, REGEXP_SUBSTR(f.Texto, N'[0-9],[0-9] bar') AS PrimeraPresion
FROM dbo.Fragmento f
WHERE REGEXP_LIKE(f.Texto, N'[0-9],[0-9] bar');
GO

/* A5. Consulta correlacionada: documentos que tienen AL MENOS un fragmento sin embedding
       (esperado: ninguno si todo esta generado) */
SELECT d.DocumentoId, d.Titulo
FROM dbo.Documento d
WHERE EXISTS (SELECT 1 FROM dbo.Fragmento f
              WHERE f.DocumentoId = d.DocumentoId AND f.Embedding IS NULL);
GO

/* A6. Subconsulta correlacionada escalar: para cada documento, el fragmento mas largo */
SELECT d.DocumentoId, d.Titulo,
       (SELECT TOP (1) f.Orden FROM dbo.Fragmento f
         WHERE f.DocumentoId = d.DocumentoId ORDER BY LEN(f.Texto) DESC) AS OrdenFragmentoMasLargo
FROM dbo.Documento d
ORDER BY d.DocumentoId;
GO
