USE MotoFix;
GO

UPDATE f
   SET f.Embedding       = AI_GENERATE_EMBEDDINGS(CONCAT(d.Titulo, N'. ', f.Texto) USE MODEL ModeloEmbeddingsOllama),
       f.EmbeddingModelo = N'qwen3-embedding:0.6b',
       f.EmbeddingFecha  = SYSDATETIME()
  FROM dbo.Fragmento f
  JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId
 WHERE f.Embedding IS NULL;
GO

SELECT COUNT(*)                                             AS TotalFragmentos,
       SUM(CASE WHEN Embedding IS NOT NULL THEN 1 ELSE 0 END) AS ConEmbedding,
       SUM(CASE WHEN Embedding IS NULL     THEN 1 ELSE 0 END) AS Pendientes
FROM dbo.Fragmento;

SELECT TOP (3) FragmentoId,
       VECTORPROPERTY(Embedding, 'Dimensions') AS Dimensiones,
       LEFT(CAST(Embedding AS NVARCHAR(MAX)), 80) + N'...' AS PrimerasComponentes
FROM dbo.Fragmento
ORDER BY FragmentoId;
GO