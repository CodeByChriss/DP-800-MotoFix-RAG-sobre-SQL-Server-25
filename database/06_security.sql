USE MotoFix;
GO

/* ------------------ 1) Roles y usuarios de demostracion ------------------ */
CREATE ROLE rol_Consulta;
CREATE ROLE rol_Recepcion;
CREATE ROLE rol_Tecnico;
CREATE ROLE rol_JefeTaller;

ALTER ROLE rol_Consulta ADD MEMBER rol_Recepcion;
ALTER ROLE rol_Consulta ADD MEMBER rol_Tecnico;
ALTER ROLE rol_Consulta ADD MEMBER rol_JefeTaller;

-- Usuarios sin login: sirven para demostrar permisos con EXECUTE AS USER
CREATE USER u_recepcion WITHOUT LOGIN;
CREATE USER u_tecnico   WITHOUT LOGIN;
CREATE USER u_jefe      WITHOUT LOGIN;

ALTER ROLE rol_Recepcion  ADD MEMBER u_recepcion;
ALTER ROLE rol_Tecnico    ADD MEMBER u_tecnico;
ALTER ROLE rol_JefeTaller ADD MEMBER u_jefe;
GO

/* ------------------ 2) Minimo privilegio ------------------ */
-- Permisos comunes: SOLO ejecutar los procedimientos y leer la vista segura
GRANT EXECUTE ON dbo.usp_BuscarFragmentos TO rol_Consulta;
GRANT EXECUTE ON dbo.usp_PreguntarRAG     TO rol_Consulta;
GRANT SELECT  ON dbo.vw_FragmentoLectura  TO rol_Consulta;

-- Los procedimientos usan el modelo de embeddings y llaman a un endpoint REST (el LLM).
-- Estos permisos de base de datos NO se heredan por encadenamiento de propiedad.
GRANT EXECUTE ON EXTERNAL MODEL::ModeloEmbeddingsOllama TO rol_Consulta;
GRANT EXECUTE ANY EXTERNAL ENDPOINT TO rol_Consulta;

-- Solo el jefe de taller puede auditar la traza del RAG y el resumen de documentos
GRANT SELECT ON dbo.vw_TrazaRAG        TO rol_JefeTaller;
GRANT SELECT ON dbo.vw_DocumentoResumen TO rol_JefeTaller;

-- DENY explicito: recepcion y tecnicos no pueden tocar ninguna tabla directamente.
-- (Los procedimientos y vistas siguen funcionando por encadenamiento de propiedad.)
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Categoria            TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.ModeloMoto           TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Documento            TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.DocumentoModelo      TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Fragmento            TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.ConsultaRAG          TO rol_Recepcion, rol_Tecnico;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.ConsultaRAGFragmento TO rol_Recepcion, rol_Tecnico;
GO

/* ------------------ 3) Dynamic Data Masking ------------------ */
ALTER TABLE dbo.Documento
    ALTER COLUMN Autor ADD MASKED WITH (FUNCTION = 'partial(2, "*****", 0)');
GO
GRANT UNMASK TO rol_JefeTaller;
GO

/* ------------------ 4) Row-Level Security ------------------ */
CREATE SCHEMA Seguridad AUTHORIZATION dbo;
GO

-- Funcion de predicado en linea: devuelve una fila (=permitido) o ninguna (=oculto)
CREATE FUNCTION Seguridad.fn_PredicadoAcceso (@NivelAcceso TINYINT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS Permitido
    WHERE  IS_MEMBER(N'db_owner')       = 1                          -- administracion
        OR IS_MEMBER(N'rol_JefeTaller') = 1                          -- niveles 1,2,3
        OR (IS_MEMBER(N'rol_Tecnico')   = 1 AND @NivelAcceso <= 2)   -- niveles 1,2
        OR (IS_MEMBER(N'rol_Recepcion') = 1 AND @NivelAcceso <= 1);  -- nivel 1
GO

CREATE SECURITY POLICY Seguridad.pol_AccesoPorNivel
    ADD FILTER PREDICATE Seguridad.fn_PredicadoAcceso(NivelAcceso) ON dbo.Documento,
    ADD FILTER PREDICATE Seguridad.fn_PredicadoAcceso(NivelAcceso) ON dbo.Fragmento
WITH (STATE = ON);
GO

/* ------------------ Comprobacion rapida ------------------ */
SELECT dp.name AS Principal, dp.type_desc
FROM sys.database_principals dp
WHERE dp.name IN (N'u_recepcion', N'u_tecnico', N'u_jefe', N'rol_Consulta', N'rol_Recepcion', N'rol_Tecnico', N'rol_JefeTaller');

SELECT name, is_enabled FROM sys.security_policies;
GO