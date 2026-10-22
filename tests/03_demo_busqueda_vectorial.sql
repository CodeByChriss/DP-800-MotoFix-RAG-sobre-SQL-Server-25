USE MotoFix;
GO
REVERT;
GO

/* ---- Caso 1: la pregunta NO comparte palabras con el documento ----
   El documento dice "el manillar vibra"; el usuario escribe "tiembla". */

-- (a) Busqueda tradicional: 0 filas (el texto no contiene "tiembla")
SELECT FragmentoId, Titulo FROM dbo.vw_FragmentoLectura WHERE Texto LIKE N'%tiembla%';

-- (b) Busqueda semantica: el documento 9 (vibracion del manillar) aparece primero
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'el manillar tiembla cuando voy rápido', @K = 3;
GO

/* ---- Caso 2: sinonimos y reformulacion ---- */
-- "palanca blanda" vs "freno esponjoso"
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'la palanca del freno se va hasta el manillar', @K = 3;
GO

/* ---- Caso 3: sintoma descrito con otras palabras ---- */
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'la moto se queda sin luz y se para mientras conduzco', @K = 3;
GO

/* ---- Caso 4: el ejemplo del enunciado (error de conexion 18456) ---- */
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'¿Cómo puedo solucionar el error de conexión 18456?', @K = 3;
GO

/* ---- Caso 5: con filtros (categoria y tipo) + ranking ---- */
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'no enciende', @K = 5, @CategoriaId = 1, @Tipo = N'Guia';
GO

/* ---- Calibrar un umbral para el RAG (@MaxDistancia):
        mira las distancias de una pregunta SIN relacion con el taller. ---- */
EXEC dbo.usp_BuscarFragmentos @Pregunta = N'¿Cuál es la capital de Francia?', @K = 3;
GO
