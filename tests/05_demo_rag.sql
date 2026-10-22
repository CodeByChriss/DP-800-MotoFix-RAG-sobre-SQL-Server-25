USE MotoFix;
GO
REVERT;
GO

/* ---------- 1) El ejemplo del enunciado ---------- */
EXEC dbo.usp_PreguntarRAG @Pregunta = N'¿Cómo puedo solucionar el error de conexión 18456?', @K = 4;
GO

/* ---------- 2) Una averia de moto (respuesta con fuentes citadas) ---------- */
EXEC dbo.usp_PreguntarRAG @Pregunta = N'La moto se apaga mientras conduzco y parpadea el piloto de la batería, ¿qué puede ser?', @K = 4;
GO

/* ---------- 3) RAG + seguridad: la misma pregunta, tres usuarios ----------
   Esperado:
     u_jefe      -> responde con la politica interna (5 %, 10 %, fidelidad 8 %)
     u_tecnico   -> "No tengo informacion suficiente..." (no ve el documento de nivel 3)
     u_recepcion -> idem                                                              */
EXECUTE AS USER = N'u_jefe';
    EXEC dbo.usp_PreguntarRAG @Pregunta = N'¿Qué descuento máximo puedo aplicar en mano de obra a un cliente habitual?', @K = 4;
REVERT;

EXECUTE AS USER = N'u_tecnico';
    EXEC dbo.usp_PreguntarRAG @Pregunta = N'¿Qué descuento máximo puedo aplicar en mano de obra a un cliente habitual?', @K = 4;
REVERT;

EXECUTE AS USER = N'u_recepcion';
    EXEC dbo.usp_PreguntarRAG @Pregunta = N'¿Qué descuento máximo puedo aplicar en mano de obra a un cliente habitual?', @K = 4;
REVERT;
GO

/* ---------- 4) Traza completa de lo ocurrido (auditoria, solo dbo/jefe) ---------- */
SELECT ConsultaId, Usuario, Pregunta, FuentesRecuperadas, DuracionMs, Estado
FROM dbo.vw_TrazaRAG
ORDER BY ConsultaId DESC;
GO

/* ---------- 5) LLM SOLO vs RAG: la misma pregunta SIN contexto de SQL Server ----------
   Sirve para explicar la diferencia: el LLM suelto no conoce las politicas del taller
   y inventa o responde en generico. RAG = SQL Server + Vector Search + Contexto + LLM. */
DECLARE @payload NVARCHAR(MAX) =
(
    SELECT N'qwen2.5:1.5b' AS model,
           CAST(0 AS BIT) AS stream,
           JSON_QUERY((SELECT N'user' AS role,
                              N'¿Qué descuento máximo puede aplicar un técnico del taller MotoFix en mano de obra?' AS content
                       FOR JSON PATH)) AS messages
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
);
DECLARE @ret INT, @resp NVARCHAR(MAX);

EXEC @ret = sys.sp_invoke_external_rest_endpoint
     @url = N'https://localhost:11435/api/chat', @method = N'POST',
     @payload = @payload, @timeout = 200, @response = @resp OUTPUT;

SELECT N'LLM sin contexto (sin RAG)' AS Modo,
       (SELECT content FROM OPENJSON(@resp, '$.result.message') WITH (content NVARCHAR(MAX) '$.content')) AS Respuesta;
GO
