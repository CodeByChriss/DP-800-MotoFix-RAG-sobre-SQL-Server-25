USE MotoFix;
GO

IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'ModeloEmbeddingsOllama')
    DROP EXTERNAL MODEL ModeloEmbeddingsOllama;
GO

CREATE EXTERNAL MODEL ModeloEmbeddingsOllama
WITH
(
    LOCATION   = 'https://localhost:11435/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'qwen3-embedding:0.6b'
);
GO

SELECT * FROM sys.external_models;
GO

DECLARE @json NVARCHAR(MAX) =
    CAST(AI_GENERATE_EMBEDDINGS(N'prueba de conexion con el modelo' USE MODEL ModeloEmbeddingsOllama) AS NVARCHAR(MAX));

SELECT COUNT(*) AS DimensionesDelModelo FROM OPENJSON(@json);

IF (SELECT COUNT(*) FROM OPENJSON(@json)) <> 1024
    PRINT N'ATENCION: la dimension no es 1024. Ajusta VECTOR(1024) en 02, 05 y 07.';
GO

DECLARE @v VECTOR(1024) = AI_GENERATE_EMBEDDINGS(N'la moto no arranca' USE MODEL ModeloEmbeddingsOllama);
SELECT VECTORPROPERTY(@v, 'Dimensions') AS Dimensiones,
       VECTORPROPERTY(@v, 'BaseType')   AS TipoBase;
GO