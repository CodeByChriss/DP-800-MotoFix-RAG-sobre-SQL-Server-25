USE MotoFix;
GO

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
    ORDER BY Distancia ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_BuscarFragmentos
    @Pregunta    NVARCHAR(1000),
    @K           INT          = 5,
    @CategoriaId INT          = NULL,
    @Tipo        NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @qv VECTOR(1024) = AI_GENERATE_EMBEDDINGS(@Pregunta USE MODEL ModeloEmbeddingsOllama);

    EXEC dbo.usp_BuscarFragmentosPorVector
         @qv = @qv, @K = @K, @CategoriaId = @CategoriaId, @Tipo = @Tipo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_PreguntarRAG
    @Pregunta     NVARCHAR(1000),
    @K            TINYINT       = 4,
    @Proveedor    NVARCHAR(20)  = N'ollama',
    @ModeloLLM    NVARCHAR(100) = NULL,
    @MaxDistancia FLOAT         = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @inicio    DATETIME2(3) = SYSDATETIME();
    DECLARE @Estado    NVARCHAR(20) = N'OK';
    DECLARE @Contexto  NVARCHAR(MAX);
    DECLARE @Respuesta NVARCHAR(MAX);
    DECLARE @ConsultaId INT;

    IF @Proveedor NOT IN (N'ollama', N'openrouter')
        THROW 50001, N'Proveedor no soportado. Usa ollama u openrouter.', 1;

    IF @ModeloLLM IS NULL
    BEGIN
        IF @Proveedor = N'ollama'
            SET @ModeloLLM = N'qwen2.5:1.5b';
        ELSE
            THROW 50002, N'Con openrouter debes indicar @ModeloLLM (por ejemplo un modelo con sufijo :free).', 1;
    END;

    CREATE TABLE #Recuperados
    (
        Rango       INT IDENTITY(1,1) PRIMARY KEY,
        FragmentoId INT,
        DocumentoId INT,
        Titulo      NVARCHAR(200),
        Tipo        NVARCHAR(20),
        Categoria   NVARCHAR(60),
        Orden       SMALLINT,
        Texto       NVARCHAR(MAX),
        Distancia   FLOAT
    );

    INSERT INTO #Recuperados (FragmentoId, DocumentoId, Titulo, Tipo, Categoria, Orden, Texto, Distancia)
    EXEC dbo.usp_BuscarFragmentos @Pregunta = @Pregunta, @K = @K;

    IF @MaxDistancia IS NOT NULL
        DELETE FROM #Recuperados WHERE Distancia > @MaxDistancia;

    DECLARE @sep NVARCHAR(10) = NCHAR(10) + NCHAR(10);

    SELECT @Contexto = STRING_AGG(
                           CAST(CONCAT(N'[Fuente ', Rango, N'] ', Titulo, NCHAR(10), Texto) AS NVARCHAR(MAX)),
                           @sep) WITHIN GROUP (ORDER BY Rango)
    FROM #Recuperados;

    IF @Contexto IS NULL
    BEGIN
        SET @Respuesta = N'No he encontrado información relevante en la base de conocimiento a la que tienes acceso.';
    END
    ELSE
    BEGIN
        BEGIN TRY
            DECLARE @sistema NVARCHAR(MAX) =
                N'Eres el asistente técnico del taller de motos MotoFix. '
              + N'Responde SIEMPRE en español y SOLO con la información del CONTEXTO. '
              + N'Si el contexto no contiene la respuesta, responde exactamente: '
              + N'"No tengo información suficiente en la base de conocimiento para responder a eso." '
              + N'Cita las fuentes con el formato [Fuente N]. No inventes datos ni uses conocimiento externo.';

            DECLARE @usuario NVARCHAR(MAX) =
                CONCAT(N'CONTEXTO:', NCHAR(10), @Contexto, NCHAR(10), NCHAR(10), N'PREGUNTA: ', @Pregunta);

            DECLARE @mensajes NVARCHAR(MAX) =
            (
                SELECT m.role, m.content
                FROM (VALUES (1, N'system', @sistema), (2, N'user', @usuario)) AS m (ord, role, content)
                ORDER BY m.ord
                FOR JSON PATH
            );

            DECLARE @payload NVARCHAR(MAX);
            DECLARE @ret  INT;
            DECLARE @resp NVARCHAR(MAX);

            IF @Proveedor = N'ollama'
            BEGIN
                SET @payload = (
                    SELECT @ModeloLLM AS model,
                           CAST(0 AS BIT) AS stream,
                           JSON_QUERY(@mensajes) AS messages,
                           JSON_QUERY(N'{"temperature":0,"num_ctx":4096}') AS options
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );

                EXEC @ret = sys.sp_invoke_external_rest_endpoint
                     @url      = N'https://localhost:11435/api/chat',
                     @method   = N'POST',
                     @payload  = @payload,
                     @timeout  = 200,
                     @response = @resp OUTPUT;

                SET @Respuesta = JSON_VALUE(@resp, '$.result.message.content');
            END
            ELSE
            BEGIN
                SET @payload =
                (
                    SELECT @ModeloLLM AS model,
                           JSON_QUERY(@mensajes) AS messages,
                           0 AS temperature
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );

                EXEC @ret = sys.sp_invoke_external_rest_endpoint
                     @url        = N'https://openrouter.ai/api/v1/chat/completions',
                     @method     = N'POST',
                     @credential = [https://openrouter.ai/api/v1],
                     @payload    = @payload,
                     @timeout    = 200,
                     @response   = @resp OUTPUT;

                SET @Respuesta = (SELECT content FROM OPENJSON(@resp, '$.result.choices[0].message')
                                  WITH (content NVARCHAR(MAX) '$.content'));
            END;

            IF @ret <> 0 OR @Respuesta IS NULL
            BEGIN
                SET @Estado = N'ERROR';
                SET @Respuesta = CONCAT(N'Fallo en la llamada al LLM. Código HTTP: ', @ret, N'. ', LEFT(@resp, 500));
            END;
        END TRY
        BEGIN CATCH
            SET @Estado = N'ERROR';
            SET @Respuesta = CONCAT(N'Excepción al llamar al LLM: ', ERROR_MESSAGE());
        END CATCH;
    END;

    DECLARE @ms INT = DATEDIFF(MILLISECOND, @inicio, SYSDATETIME());

    INSERT INTO dbo.ConsultaRAG (Pregunta, Proveedor, ModeloLLM, K, Contexto, Respuesta, DuracionMs, Estado)
    VALUES (@Pregunta, @Proveedor, @ModeloLLM, @K, @Contexto, @Respuesta, @ms, @Estado);

    SET @ConsultaId = SCOPE_IDENTITY();

    INSERT INTO dbo.ConsultaRAGFragmento (ConsultaId, Rango, FragmentoId, Distancia)
    SELECT @ConsultaId, Rango, FragmentoId, Distancia FROM #Recuperados;

    SELECT Rango, Titulo, Tipo, Categoria, Orden,
           ROUND(Distancia, 4) AS Distancia,
           dbo.fn_Extracto(Texto, 150) AS Extracto
    FROM   #Recuperados
    ORDER BY Rango;

    SELECT @ConsultaId AS ConsultaId,
           USER_NAME() AS Usuario,
           @Pregunta   AS Pregunta,
           @Contexto   AS ContextoEnviadoAlLLM,
           @Respuesta  AS RespuestaFinal,
           @ms         AS DuracionMs,
           @Estado     AS Estado,
           @resp       AS JsonCompletoDevueltoPorSql;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegenerarEmbeddingsPendientes
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
       SET f.Embedding       = AI_GENERATE_EMBEDDINGS(CONCAT(d.Titulo, N'. ', f.Texto) USE MODEL ModeloEmbeddingsOllama),
           f.EmbeddingModelo = N'qwen3-embedding:0.6b',
           f.EmbeddingFecha  = SYSDATETIME()
      FROM dbo.Fragmento f
      JOIN dbo.Documento d ON d.DocumentoId = f.DocumentoId
     WHERE f.Embedding IS NULL;

    SELECT @@ROWCOUNT AS FragmentosActualizados;
END;
GO

SELECT name, create_date FROM sys.procedures ORDER BY name;
GO