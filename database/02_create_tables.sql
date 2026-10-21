USE MotoFix;
GO

CREATE TABLE dbo.Categoria
(
    CategoriaId  INT IDENTITY(1,1) NOT NULL,
    Nombre       NVARCHAR(60)  NOT NULL,
    Descripcion  NVARCHAR(200) NULL,
    CONSTRAINT PK_Categoria        PRIMARY KEY (CategoriaId),
    CONSTRAINT UQ_Categoria_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE dbo.ModeloMoto
(
    ModeloId     INT IDENTITY(1,1) NOT NULL,
    Marca        NVARCHAR(40)  NOT NULL,
    Modelo       NVARCHAR(60)  NOT NULL,
    CilindradaCc SMALLINT      NOT NULL,
    Tipo         NVARCHAR(30)  NOT NULL,
    CONSTRAINT PK_ModeloMoto    PRIMARY KEY (ModeloId),
    CONSTRAINT UQ_ModeloMoto    UNIQUE (Marca, Modelo),
    CONSTRAINT CK_ModeloMoto_Cc CHECK (CilindradaCc BETWEEN 49 AND 2500)
);
GO

CREATE TABLE dbo.Documento
(
    DocumentoId       INT IDENTITY(1,1) NOT NULL,
    CategoriaId       INT           NOT NULL,
    Titulo            NVARCHAR(200) NOT NULL,
    Tipo              NVARCHAR(20)  NOT NULL,
    NivelAcceso       TINYINT       NOT NULL
        CONSTRAINT DF_Documento_Nivel DEFAULT (1),
    Autor             NVARCHAR(80)  NOT NULL,
    Activo            BIT           NOT NULL
        CONSTRAINT DF_Documento_Activo DEFAULT (1),
    FechaAlta         DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Documento_FechaAlta DEFAULT (SYSDATETIME()),
    FechaModificacion DATETIME2(0)  NULL,
    CONSTRAINT PK_Documento           PRIMARY KEY (DocumentoId),
    CONSTRAINT UQ_Documento_Titulo    UNIQUE (Titulo),
    CONSTRAINT FK_Documento_Categoria FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria (CategoriaId),
    CONSTRAINT CK_Documento_Tipo      CHECK (Tipo IN (N'Incidencia', N'Guia', N'FAQ')),
    CONSTRAINT CK_Documento_Nivel     CHECK (NivelAcceso BETWEEN 1 AND 3)
);
GO

CREATE TABLE dbo.DocumentoModelo
(
    DocumentoId INT NOT NULL,
    ModeloId    INT NOT NULL,
    CONSTRAINT PK_DocumentoModelo PRIMARY KEY (DocumentoId, ModeloId),
    CONSTRAINT FK_DocMod_Documento FOREIGN KEY (DocumentoId) REFERENCES dbo.Documento (DocumentoId) ON DELETE CASCADE,
    CONSTRAINT FK_DocMod_Modelo    FOREIGN KEY (ModeloId)    REFERENCES dbo.ModeloMoto (ModeloId)
);
GO

CREATE TABLE dbo.Fragmento
(
    FragmentoId     INT IDENTITY(1,1) NOT NULL,
    DocumentoId     INT           NOT NULL,
    Orden           SMALLINT      NOT NULL,
    Texto           NVARCHAR(MAX) NOT NULL,
    NivelAcceso     TINYINT       NOT NULL,
    Embedding       VECTOR(1024)  NULL,
    EmbeddingModelo NVARCHAR(100) NULL,
    EmbeddingFecha  DATETIME2(0)  NULL,
    CONSTRAINT PK_Fragmento           PRIMARY KEY (FragmentoId),
    CONSTRAINT FK_Fragmento_Documento FOREIGN KEY (DocumentoId) REFERENCES dbo.Documento (DocumentoId) ON DELETE CASCADE,
    CONSTRAINT CK_Fragmento_Nivel     CHECK (NivelAcceso BETWEEN 1 AND 3),
    CONSTRAINT CK_Fragmento_Orden     CHECK (Orden > 0)
);
GO

CREATE TABLE dbo.ConsultaRAG
(
    ConsultaId INT IDENTITY(1,1) NOT NULL,
    Usuario    SYSNAME       NOT NULL CONSTRAINT DF_ConsultaRAG_Usuario DEFAULT (USER_NAME()),
    FechaHora  DATETIME2(0)  NOT NULL CONSTRAINT DF_ConsultaRAG_Fecha   DEFAULT (SYSDATETIME()),
    Pregunta   NVARCHAR(1000) NOT NULL,
    Proveedor  NVARCHAR(20)  NOT NULL,
    ModeloLLM  NVARCHAR(100) NOT NULL,
    K          TINYINT       NOT NULL,
    Contexto   NVARCHAR(MAX) NULL,
    Respuesta  NVARCHAR(MAX) NULL,
    DuracionMs INT           NULL,
    Estado     NVARCHAR(20)  NOT NULL CONSTRAINT DF_ConsultaRAG_Estado DEFAULT (N'OK'),
    CONSTRAINT PK_ConsultaRAG        PRIMARY KEY (ConsultaId),
    CONSTRAINT CK_ConsultaRAG_Estado CHECK (Estado IN (N'OK', N'ERROR'))
);
GO

CREATE TABLE dbo.ConsultaRAGFragmento
(
    ConsultaId  INT   NOT NULL,
    Rango       TINYINT NOT NULL,
    FragmentoId INT   NOT NULL,
    Distancia   FLOAT NOT NULL,
    CONSTRAINT PK_ConsultaRAGFragmento PRIMARY KEY (ConsultaId, Rango),
    CONSTRAINT FK_CRF_Consulta  FOREIGN KEY (ConsultaId)  REFERENCES dbo.ConsultaRAG (ConsultaId) ON DELETE CASCADE,
    CONSTRAINT FK_CRF_Fragmento FOREIGN KEY (FragmentoId) REFERENCES dbo.Fragmento (FragmentoId)
);
GO

SELECT t.name AS Tabla, COUNT(c.column_id) AS Columnas
FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id
GROUP BY t.name ORDER BY t.name;
GO
