USE MotoFix;
GO
SET NOCOUNT ON;

SET IDENTITY_INSERT dbo.Categoria ON;
INSERT INTO dbo.Categoria (CategoriaId, Nombre, Descripcion) VALUES
 (1, N'Motor y combustible',               N'Arranque, alimentación, refrigeración, consumo de aceite'),
 (2, N'Sistema eléctrico',                 N'Batería, carga, luces y centralitas'),
 (3, N'Frenos y suspensión',               N'Circuito hidráulico, pastillas, horquilla y amortiguador'),
 (4, N'Transmisión',                       N'Cadena, embrague y caja de cambios'),
 (5, N'Neumáticos y ruedas',               N'Presiones, desgaste, equilibrado y rodamientos'),
 (6, N'Mantenimiento programado',          N'Revisiones periódicas según fabricante'),
 (7, N'Sistemas informáticos del taller',  N'Programa de gestión, servidor SQL y copias de seguridad'),
 (8, N'Atención al cliente y garantías',   N'Plazos, garantías, descuentos y reclamaciones');
SET IDENTITY_INSERT dbo.Categoria OFF;

SET IDENTITY_INSERT dbo.ModeloMoto ON;
INSERT INTO dbo.ModeloMoto (ModeloId, Marca, Modelo, CilindradaCc, Tipo) VALUES
 (1, N'Honda',    N'CB500F',       500,  N'Naked'),
 (2, N'Yamaha',   N'MT-07',        689,  N'Naked'),
 (3, N'Kawasaki', N'Z650',         649,  N'Naked'),
 (4, N'Suzuki',   N'V-Strom 650',  645,  N'Trail'),
 (5, N'BMW',      N'R 1250 GS',    1254, N'Trail'),
 (6, N'Vespa',    N'GTS 300',      278,  N'Scooter'),
 (7, N'Honda',    N'PCX 125',      125,  N'Scooter'),
 (8, N'KTM',      N'390 Duke',     373,  N'Naked');
SET IDENTITY_INSERT dbo.ModeloMoto OFF;

SET IDENTITY_INSERT dbo.Documento ON;
INSERT INTO dbo.Documento (DocumentoId, CategoriaId, Titulo, Tipo, NivelAcceso, Autor) VALUES
 (1,  6, N'FAQ: Cada cuánto debo llevar mi moto a revisión',                      N'FAQ',        1, N'Recepción MotoFix'),
 (2,  8, N'FAQ: Qué cubre la garantía de una reparación',                         N'FAQ',        1, N'Recepción MotoFix'),
 (3,  8, N'FAQ: Cuánto tarda una reparación y cómo consulto el estado',           N'FAQ',        1, N'Recepción MotoFix'),
 (4,  5, N'FAQ: Presión de los neumáticos y cuando cambiarlos',                   N'FAQ',        1, N'Recepción MotoFix'),
 (5,  1, N'Guía: La moto no arranca aunque el motor de arranque gira',            N'Guia',       2, N'Marcos Ibáñez'),
 (6,  2, N'Guía: Diagnóstico de batería descargada y sistema de carga',           N'Guia',       2, N'Marcos Ibáñez'),
 (7,  2, N'Incidencia: Se apaga en marcha y parpadea el testigo de batería',      N'Incidencia', 2, N'Laura Méndez'),
 (8,  3, N'Guía: Freno blando o esponjoso, purga y cambio de líquido',            N'Guia',       2, N'Laura Méndez'),
 (9,  5, N'Incidencia: El manillar vibra a partir de 90 km/h',                    N'Incidencia', 2, N'Pablo Serrano'),
 (10, 4, N'Guía: Cadena de transmisión, tensión, engrase y desgaste',             N'Guia',       2, N'Pablo Serrano'),
 (11, 4, N'Incidencia: Ruido al cambiar de marcha y marcha que salta',            N'Incidencia', 2, N'Marcos Ibáñez'),
 (12, 1, N'Incidencia: Sobrecalentamiento en ciudad y ventilador que no se activa', N'Incidencia', 2, N'Laura Méndez'),
 (13, 7, N'Incidencia: Error 18456 al abrir el programa de gestión del taller',   N'Incidencia', 2, N'Soporte IT MotoFix'),
 (14, 1, N'Guía: Humo azul y consumo excesivo de aceite',                         N'Guia',       2, N'Pablo Serrano'),
 (15, 8, N'Procedimiento interno: descuentos y márgenes en mano de obra',         N'Guia',       3, N'Gerencia MotoFix'),
 (16, 8, N'Procedimiento interno: reclamaciones de garantía al fabricante',       N'Guia',       3, N'Gerencia MotoFix'),
 (17, 7, N'Incidencia interna: Falla la copia de seguridad nocturna del servidor', N'Incidencia', 3, N'Soporte IT MotoFix');
SET IDENTITY_INSERT dbo.Documento OFF;

INSERT INTO dbo.DocumentoModelo (DocumentoId, ModeloId) VALUES
 (5,1),(5,2),(5,3),(5,8),
 (7,2),(7,3),(7,4),
 (8,1),(8,2),(8,3),(8,4),(8,5),
 (9,4),(9,5),
 (10,1),(10,2),(10,3),(10,8),
 (11,1),(11,3),
 (12,6),(12,7),
 (14,1),(14,2),(14,3);

INSERT INTO dbo.Fragmento (DocumentoId, Orden, Texto, NivelAcceso)
SELECT v.DocumentoId, v.Orden, v.Texto, d.NivelAcceso
FROM (VALUES
 (1, 1, N'Las motos de uso normal deben pasar revisión cada 6.000 a 12.000 km o una vez al año, lo que ocurra primero. El plan exacto depende del modelo y se indica en el libro de mantenimiento del fabricante. Si usas la moto en ciudad con muchas paradas o en condiciones duras, conviene acortar los intervalos.'),
 (1, 2, N'En cada revisión cambiamos el aceite y el filtro, comprobamos frenos, neumáticos, cadena, batería y luces, y revisamos el nivel del líquido de frenos y del refrigerante. El líquido de frenos se sustituye como mínimo cada dos años aunque no se alcancen los kilómetros.'),
 (2, 1, N'Todas las reparaciones tienen una garantía de 12 meses o 10.000 km sobre la mano de obra y las piezas sustituidas, lo que ocurra primero. La garantía cubre defectos de la pieza o de la reparación realizada.'),
 (2, 2, N'La garantía no cubre el desgaste normal de consumibles como pastillas, neumáticos, cadena o embrague, ni averías causadas por un mal uso, caídas o falta de mantenimiento. Para hacerla valer hay que presentar la factura de la reparación.'),
 (3, 1, N'Una revisión de mantenimiento se realiza normalmente en el mismo día. Una reparación de motor o caja de cambios puede tardar entre 3 y 10 días laborables según la disponibilidad de piezas. Siempre se avisa al cliente antes de superar el presupuesto aprobado.'),
 (3, 2, N'El cliente puede consultar el estado de su orden de trabajo llamando al taller o por mensaje indicando la matrícula. Los estados posibles son recibida, en diagnóstico, esperando pieza, en reparación y lista para recoger.'),
 (4, 1, N'La presión recomendada para la mayoría de motos de calle es de 2,2 bar delante y 2,5 bar detrás, medida en frío, pero hay que seguir siempre la indicada por el fabricante en el manual o en la pegatina del basculante. Con pasajero y equipaje se suele subir 0,2 bar detrás.'),
 (4, 2, N'Conviene cambiar el neumático cuando el dibujo llega al indicador de desgaste (TWI) o al mínimo legal, o cuando tiene grietas, bultos o más de 5 a 6 años desde su fabricación, aunque parezca en buen estado. La fecha de fabricación está en el flanco en formato semana y año.'),
 (5, 1, N'Si el motor de arranque gira con fuerza pero la moto no enciende, el problema suele estar en una de las tres condiciones del motor: chispa, combustible o aire. Primero comprueba que el interruptor de parada este en posición de marcha y que el caballete lateral este recogido, porque el sensor impide arrancar.'),
 (5, 2, N'Para descartar chispa, retira una bujía, conéctala a su pipa y apóyala contra masa mientras das al arranque: debe saltar una chispa azulada constante. Si no hay chispa, revisa bobinas, pipas y el sensor de posición del cigüeñal. Si hay chispa, comprueba que la bomba de gasolina presuriza al dar contacto y que el filtro de aire no este obstruido.'),
 (5, 3, N'Una gasolina vieja o con agua tras semanas de parada es otra causa frecuente. Vacía el depósito, limpia el circuito y sustituye el filtro de combustible. En motos con carburador revisa también los surtidores de ralentí, que se obstruyen con facilidad.'),
 (6, 1, N'Una batería sana de 12 V debe marcar entre 12,6 y 12,8 V en reposo. Por debajo de 12,4 V está parcialmente descargada y por debajo de 12,0 V suele estar sulfatada o en mal estado. Mide siempre tras dejar la moto sin uso varias horas para evitar lecturas falsas.'),
 (6, 2, N'Para comprobar el sistema de carga arranca la moto y mide en bornes con el motor a 4.000 rpm: la tensión debe estar entre 13,8 y 14,8 V. Si es inferior, falla el alternador o el regulador. Si supera 15 V, el regulador está dañado y puede hervir la batería.'),
 (6, 3, N'Con la moto parada y todo apagado, intercala el polímetro en serie para medir el consumo parásito: no debería superar 20 a 30 mA. Un consumo mayor indica un accesorio mal conectado, como alarmas o tomas USB, que descarga la batería durante la noche.'),
 (7, 1, N'Síntoma: durante la marcha parpadea el testigo de batería, el cuadro pierde brillo y la moto acaba apagándose. Después arranca con ayuda externa y funciona unos minutos. Esto indica que la batería se está descargando porque no recibe carga del alternador.'),
 (7, 2, N'Causa más probable: regulador rectificador defectuoso o conector quemado entre el alternador y el regulador. Revisa el conector trifásico: si está marrón o derretido, hay que sustituir la pieza y el mazo de cables. Mide la resistencia entre fases del estator, que debe ser baja y similar en las tres.'),
 (7, 3, N'Solución: sustituir el regulador rectificador y los conectores dañados, comprobar el estator y cargar o cambiar la batería. Después repite la medida de carga a 4.000 rpm, que debe estar entre 13,8 y 14,8 V, y deja la moto en marcha 15 minutos antes de entregarla.'),
 (8, 1, N'Cuando la palanca de freno se siente blanda o esponjosa y llega casi al puño, normalmente hay aire en el circuito hidráulico, líquido degradado o una fuga. Antes de purgar, comprueba el nivel del depósito, el estado de los latiguillos y que no haya fugas en las pinzas ni en la bomba.'),
 (8, 2, N'Para purgar, mantén el depósito lleno con líquido DOT 4 nuevo, conecta un tubo transparente al purgador de la pinza, acciona la palanca varias veces, mantenla apretada y abre el purgador para dejar salir el aire. Cierra antes de soltar la palanca y repite hasta que salga líquido limpio sin burbujas.'),
 (8, 3, N'Si tras purgar la palanca sigue blanda, revisa el estado de los retenes de la bomba y de las pinzas, y valora sustituir los latiguillos por unos de malla metálica. Nunca mezcles líquidos DOT 5 con DOT 3 o DOT 4. Comprueba el freno con prueba en carretera antes de entregar.'),
 (9, 1, N'Síntoma: el manillar vibra o se mueve cuando la moto supera los 90 km/h. Las causas más habituales son ruedas desequilibradas, neumático deformado o con desgaste irregular, rodamientos de la dirección con holgura o una llanta ligeramente doblada.'),
 (9, 2, N'Diagnóstico: levanta la rueda delantera y mueve el manillar de lado a lado, no deben notarse puntos duros ni holgura al balancear la horquilla. Equilibra la rueda en la máquina y comprueba el descentrado de la llanta. Si persiste, sustituye los rodamientos de dirección y reengrasa.'),
 (10, 1, N'La tensión de la cadena debe permitir un juego libre de unos 25 a 35 mm en el punto medio del ramal inferior, aunque la cifra exacta es la del manual del modelo. Mide con la moto sobre el caballete, en varios puntos de la cadena, ya que puede desgastarse de forma desigual.'),
 (10, 2, N'Engrasa la cadena cada 500 a 1.000 km y después de circular con lluvia, usando lubricante específico para cadenas con retenes. Limpia antes con un cepillo y desengrasante apto para retenes tóricos. Una cadena seca o con exceso de tensión se desgasta rápido y puede dañar la caja de cambios.'),
 (10, 3, N'Cambia el kit completo (cadena, piñón y corona) a la vez. Señales de desgaste: dientes de la corona en forma de gancho o de aleta de tiburón, eslabones rígidos que no se mueven con libertad y cadena que se estira más del 2 por ciento medido a lo largo de 20 eslabones.'),
 (11, 1, N'Síntoma: ruido metálico al cambiar de marcha, cambio duro o una marcha que salta, sobre todo en segunda o tercera al acelerar con fuerza. Puede tratarse de un embrague que no desembraga bien, aceite de motor degradado o desgaste de las horquillas selectoras y los dientes de los piñones.'),
 (11, 2, N'Primero cambia el aceite y el filtro con la viscosidad correcta y revisa el recorrido y el juego libre de la palanca de embrague. Purga o ajusta el embrague. Si la marcha sigue saltando, hay que abrir la caja de cambios para comprobar las horquillas selectoras, que es una reparación larga: avisa al jefe de taller del presupuesto.'),
 (12, 1, N'Síntoma: la temperatura sube en tráfico urbano o con la moto parada, el testigo se enciende o el refrigerante hierve. En motos refrigeradas por líquido el ventilador debe activarse al llegar a unos 100 a 105 grados. Si no lo hace, el motor puede sobrecalentarse en pocos minutos.'),
 (12, 2, N'Diagnóstico: con el motor caliente, comprueba que llega corriente al ventilador puenteando su conector. Si gira, falla el termocontacto o el sensor de temperatura. Si no gira, sustituye el motor del ventilador. Revisa también el nivel de refrigerante, el tapón del radiador y la bomba de agua.'),
 (12, 3, N'Purga el circuito de refrigeración tras cualquier sustitución para eliminar el aire, y no abras el tapón del radiador con el motor caliente. Sustituye el refrigerante cada dos o tres años siguiendo el manual del fabricante.'),
 (13, 1, N'Error 18456 en el programa de gestión del taller: el mensaje Error de inicio de sesión del usuario indica que SQL Server rechazó las credenciales con las que se conectó el programa. El motivo real no aparece en el mensaje al usuario y hay que consultarlo en el registro de errores de SQL Server, donde figura un número de estado.'),
 (13, 2, N'Interpreta el estado del registro: estado 2 o 5, el usuario no existe; estado 8, contraseña incorrecta; estado 7, el login está deshabilitado; estado 11 o 12, el login es válido pero no tiene acceso al servidor; estado 38, la base de datos predeterminada no existe o no está disponible. Revisa el registro en SSMS, dentro de Administración, Registros de SQL Server.'),
 (13, 3, N'Solución habitual: si es la contraseña, restablécela y actualiza la cadena de conexión del programa; si el login está deshabilitado, habilítalo con ALTER LOGIN; si el servidor usa solo autenticación de Windows, activa el modo mixto y reinicia el servicio. Comprueba también que el servidor SQL del taller este iniciado y accesible desde el equipo del mostrador.'),
 (14, 1, N'Un humo azulado por el escape y un consumo de aceite superior a 0,5 litros cada 1.000 km indican que el aceite está llegando a la cámara de combustión. Las causas habituales son segmentos de pistón desgastados, retenes de válvula endurecidos, guías de válvula con holgura o exceso de nivel de aceite.'),
 (14, 2, N'Comprueba primero el nivel de aceite y que no se haya llenado de más. Haz una prueba de compresión y una prueba de estanqueidad del cilindro para localizar si el fallo está en los segmentos o en las válvulas. Si el humo aparece sobre todo al soltar el gas tras una bajada, sospecha de los retenes de válvula.'),
 (14, 3, N'Si la reparación implica abrir el motor, informa al cliente del coste estimado y del plazo antes de empezar. Ten en cuenta que un motor con mucho kilometraje puede no compensar económicamente: ofrece las opciones por escrito.'),
 (15, 1, N'Política interna: el descuento máximo que puede aplicar un técnico en mano de obra es del 5 por ciento. Entre el 5 y el 10 por ciento requiere autorización del jefe de taller. Los descuentos superiores al 10 por ciento solo los aprueba la gerencia y se registran en la orden de trabajo.'),
 (15, 2, N'Los clientes habituales con más de tres reparaciones al año pueden recibir un descuento de fidelidad del 8 por ciento en mano de obra, nunca en piezas. El margen mínimo objetivo sobre piezas es del 25 por ciento y sobre mano de obra del 40 por ciento. Esta información es confidencial y no debe comunicarse al cliente.'),
 (16, 1, N'Reclamación de garantía al fabricante: tras confirmar el defecto, fotografía la pieza y el número de bastidor, rellena el formulario del fabricante y adjunta la factura de compra y la orden de trabajo. El plazo máximo para presentar la reclamación es de 30 días desde la reparación.'),
 (16, 2, N'El fabricante suele abonar las piezas y un baremo de horas de mano de obra inferior al coste real del taller, por lo que la diferencia la asume MotoFix. Guarda la pieza defectuosa durante 60 días por si el fabricante solicita su devolución. Información interna: no compartir con clientes.'),
 (17, 1, N'La copia de seguridad nocturna del servidor SQL del taller falla con el error de disco lleno en la unidad de copias. Comprueba el espacio libre, elimina las copias anteriores a 14 días y revisa el trabajo del Agente SQL Server en el historial de trabajos para ver el paso que falla.'),
 (17, 2, N'Para restaurar el servicio ejecuta una copia completa manual con BACKUP DATABASE con compresión y verifica con RESTORE VERIFYONLY. Si el problema se repite, mueve las copias a la unidad externa y configura una alerta del Agente cuando el espacio libre baje del 15 por ciento. Las credenciales de la unidad de red están en el gestor de contraseñas de gerencia.')
) AS v (DocumentoId, Orden, Texto)
JOIN dbo.Documento AS d ON d.DocumentoId = v.DocumentoId;
GO

SELECT 'Categoria' AS Tabla, COUNT(*) AS Filas FROM dbo.Categoria
UNION ALL SELECT 'ModeloMoto',      COUNT(*) FROM dbo.ModeloMoto
UNION ALL SELECT 'Documento',       COUNT(*) FROM dbo.Documento
UNION ALL SELECT 'DocumentoModelo', COUNT(*) FROM dbo.DocumentoModelo
UNION ALL SELECT 'Fragmento',       COUNT(*) FROM dbo.Fragmento;

SELECT NivelAcceso, COUNT(*) AS Fragmentos FROM dbo.Fragmento GROUP BY NivelAcceso ORDER BY NivelAcceso;
GO