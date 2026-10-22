USE MotoFix;
GO
REVERT;
GO

/* ---------- 1) Filas visibles segun el usuario (Row-Level Security) ----------
   Esperado: dbo = 42 | u_jefe = 42 | u_tecnico = 36 | u_recepcion = 8 */
SELECT USER_NAME() AS Usuario, COUNT(*) AS FragmentosVisibles FROM dbo.vw_FragmentoLectura;

EXECUTE AS USER = N'u_jefe';
    SELECT USER_NAME() AS Usuario, COUNT(*) AS FragmentosVisibles FROM dbo.vw_FragmentoLectura;
REVERT;

EXECUTE AS USER = N'u_tecnico';
    SELECT USER_NAME() AS Usuario, COUNT(*) AS FragmentosVisibles FROM dbo.vw_FragmentoLectura;
REVERT;

EXECUTE AS USER = N'u_recepcion';
    SELECT USER_NAME() AS Usuario, COUNT(*) AS FragmentosVisibles FROM dbo.vw_FragmentoLectura;
REVERT;
GO

/* ---------- 2) Minimo privilegio: acceso directo a las tablas DENEGADO ----------
   Esperado: error 229 (permiso SELECT denegado) para tecnico y recepcion */
EXECUTE AS USER = N'u_tecnico';
BEGIN TRY
    SELECT TOP (1) * FROM dbo.Fragmento;
END TRY
BEGIN CATCH
    SELECT USER_NAME() AS Usuario, ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH;
REVERT;

EXECUTE AS USER = N'u_recepcion';
BEGIN TRY
    DELETE FROM dbo.Documento;      -- intento destructivo
END TRY
BEGIN CATCH
    SELECT USER_NAME() AS Usuario, ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH;
REVERT;
GO

/* ---------- 3) Dynamic Data Masking: columna Autor ----------
   Esperado: recepcion ve "Re*****"; el jefe ve el nombre completo */
EXECUTE AS USER = N'u_recepcion';
    SELECT TOP (3) USER_NAME() AS Usuario, Titulo, Autor FROM dbo.vw_FragmentoLectura ORDER BY FragmentoId;
REVERT;

EXECUTE AS USER = N'u_jefe';
    SELECT TOP (3) USER_NAME() AS Usuario, Titulo, Autor FROM dbo.vw_FragmentoLectura ORDER BY FragmentoId;
REVERT;
GO

/* ---------- 4) La MISMA busqueda semantica devuelve resultados distintos ----------
   Pregunta sobre politica interna de descuentos (documento de nivel 3):
     u_jefe      -> el documento 15 aparece en primer lugar
     u_tecnico   -> NO aparece (RLS lo oculta); salen fragmentos poco relacionados
     u_recepcion -> idem, aun mas restringido                                          */
EXECUTE AS USER = N'u_jefe';
    SELECT USER_NAME() AS Usuario;
    EXEC dbo.usp_BuscarFragmentos @Pregunta = N'¿Qué descuento máximo puedo hacer a un cliente habitual?', @K = 3;
REVERT;

EXECUTE AS USER = N'u_tecnico';
    SELECT USER_NAME() AS Usuario;
    EXEC dbo.usp_BuscarFragmentos @Pregunta = N'¿Qué descuento máximo puedo hacer a un cliente habitual?', @K = 3;
REVERT;

EXECUTE AS USER = N'u_recepcion';
    SELECT USER_NAME() AS Usuario;
    EXEC dbo.usp_BuscarFragmentos @Pregunta = N'¿Qué descuento máximo puedo hacer a un cliente habitual?', @K = 3;
REVERT;
GO

/* ---------- 5) Inventario de la configuracion de seguridad (para la documentacion) ---------- */
SELECT name, is_enabled, is_schema_bound FROM sys.security_policies;
SELECT OBJECT_NAME(object_id) AS Tabla, predicate_definition, predicate_type_desc
FROM sys.security_predicates;
SELECT OBJECT_NAME(object_id) AS Tabla, name AS Columna, masking_function
FROM sys.masked_columns;
GO
