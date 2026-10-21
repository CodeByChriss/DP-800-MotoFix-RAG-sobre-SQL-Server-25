USE MotoFix;
GO

/* ------------------------------ VISTAS ------------------------------ */

-- Resumen por documento (incluye cuantos fragmentos ya tienen embedding)
CREATE OR ALTER VIEW dbo.vw_DocumentoResumen
AS
SELECT  d.DocumentoId,
        d.Titulo,
        d.Tipo,
        c.Nombre AS Categoria,
        d.NivelAcceso,
        d.Autor,
        d.Activo,
        (SELECT COUNT(*) FROM dbo.Fragmento f WHERE f.DocumentoId = d.DocumentoId) AS NumFragmentos,
        (SELECT COUNT(*) FROM dbo.Fragmento f WHERE f.DocumentoId = d.DocumentoId AND f.Embedding IS NOT NULL) AS NumConEmbedding,
        (SELECT STRING_AGG(CONCAT(m.Marca, N' ', m.Modelo), N', ')
           FROM dbo.DocumentoModelo dm
           JOIN dbo.ModeloMoto m ON m.ModeloId = dm.ModeloId
          WHERE dm.DocumentoId = d.DocumentoId) AS Modelos
FROM    dbo.Documento d
JOIN    dbo.Categoria c ON c.CategoriaId = d.CategoriaId;
GO

-- Lectura segura de fragmentos: NO expone la columna vector (pesada) y la usa el rol de consulta
CREATE OR ALTER VIEW dbo.vw_FragmentoLectura
AS
SELECT  f.FragmentoId,
        d.DocumentoId,
        d.Titulo,
        d.Tipo,
        c.Nombre AS Categoria,
        f.Orden,
        f.Texto,
        f.NivelAcceso,
        d.Autor,
        CAST(CASE WHEN f.Embedding IS NULL THEN 0 ELSE 1 END AS BIT) AS TieneEmbedding
FROM    dbo.Fragmento f
JOIN    dbo.Documento d ON d.DocumentoId = f.DocumentoId
JOIN    dbo.Categoria c ON c.CategoriaId = d.CategoriaId
WHERE   d.Activo = 1;
GO

-- Los fragmentos que están pendientes de generar embedding
CREATE OR ALTER VIEW dbo.vw_FragmentoPendiente
AS
SELECT  f.FragmentoId, f.DocumentoId, f.Orden, LEN(f.Texto) AS Caracteres
FROM    dbo.Fragmento f
WHERE   f.Embedding IS NULL;
GO

-- Trazabilidad del RAG: pregunta, fuentes usadas, contexto y respuesta
CREATE OR ALTER VIEW dbo.vw_TrazaRAG
AS
SELECT  q.ConsultaId,
        q.FechaHora,
        q.Usuario,
        q.Pregunta,
        q.Proveedor,
        q.ModeloLLM,
        q.DuracionMs,
        q.Estado,
        (SELECT STRING_AGG(CONCAT(r.Rango, N':doc', f.DocumentoId, N'/frag', f.FragmentoId,
                                  N' (', FORMAT(r.Distancia, 'N3'), N')'), N' | ')
                WITHIN GROUP (ORDER BY r.Rango)
           FROM dbo.ConsultaRAGFragmento r
           JOIN dbo.Fragmento f ON f.FragmentoId = r.FragmentoId
          WHERE r.ConsultaId = q.ConsultaId) AS FuentesRecuperadas,
        q.Contexto,
        q.Respuesta
FROM    dbo.ConsultaRAG q;
GO

/* ----------------------------- FUNCIONES ---------------------------- */

-- Obtener los documentos aplicables a un modelo de moto
CREATE OR ALTER FUNCTION dbo.fn_DocumentosPorModelo (@ModeloId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT d.DocumentoId, d.Titulo, d.Tipo, c.Nombre AS Categoria
    FROM   dbo.DocumentoModelo dm
    JOIN   dbo.Documento d ON d.DocumentoId = dm.DocumentoId
    JOIN   dbo.Categoria c ON c.CategoriaId = d.CategoriaId
    WHERE  dm.ModeloId = @ModeloId
      AND  d.Activo = 1
);
GO

-- Funcion escalar: extracto corto de un texto largo (max. 500 caracteres)
CREATE OR ALTER FUNCTION dbo.fn_Extracto (@Texto NVARCHAR(MAX), @Max INT)
RETURNS NVARCHAR(500)
AS
BEGIN
    RETURN CASE WHEN LEN(@Texto) <= @Max THEN LEFT(@Texto, 500)
                ELSE LEFT(@Texto, CASE WHEN @Max > 500 THEN 497 ELSE @Max - 3 END) + N'...'
           END;
END;
GO

/* ----------------------------- TRIGGERS ----------------------------- */

-- 1) Al modificar un documento: sella FechaModificacion y propaga el NivelAcceso a sus fragmentos
--    (RLS filtra por Fragmento.NivelAcceso, que debe ser siempre coherente con el documento)
CREATE OR ALTER TRIGGER dbo.trg_Documento_Actualizar
ON dbo.Documento
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE d
       SET FechaModificacion = SYSDATETIME()
      FROM dbo.Documento d
      JOIN inserted i ON i.DocumentoId = d.DocumentoId;

    IF UPDATE(NivelAcceso)
        UPDATE f
           SET NivelAcceso = i.NivelAcceso
          FROM dbo.Fragmento f
          JOIN inserted i ON i.DocumentoId = f.DocumentoId;
END;
GO

-- Si cambia el TEXTO de un fragmento su embedding queda obsoleto: se invalida poniendo todo NULL
CREATE OR ALTER TRIGGER dbo.trg_Fragmento_InvalidarEmbedding
ON dbo.Fragmento
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Texto) AND NOT UPDATE(Embedding)
        UPDATE f
           SET Embedding = NULL, EmbeddingModelo = NULL, EmbeddingFecha = NULL
          FROM dbo.Fragmento f
          JOIN inserted i ON i.FragmentoId = f.FragmentoId;
END;
GO

SELECT name, type_desc FROM sys.objects
WHERE type IN ('V','IF','FN','TR') AND is_ms_shipped = 0
ORDER BY type_desc, name;
GO
