-- =====================================================================
-- 01_base_datos_inmobiliaria.sql
-- Proyecto: InmobiliariaWeb - Sistema de Gestión Inmobiliaria
-- Estudiantes: UTS - Tecnología en Desarrollo de Sistemas Informáticos
-- Arquitectura: Modelo 1 con JSP + .jspf + JDBC nativo + MySQL 8 + Bootstrap 5
-- Esquema: inmobiliaria_db
-- =====================================================================

DROP DATABASE IF EXISTS inmobiliaria_db;
CREATE DATABASE inmobiliaria_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE inmobiliaria_db;

-- =====================================================================
-- 1) TABLA: rol
-- =====================================================================
CREATE TABLE rol (
    id_rol      INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(30) NOT NULL,
    descripcion VARCHAR(150),
    activo      TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- =====================================================================
-- 2) TABLA: usuario (Credenciales y estado)
-- Restricción UNIQUE en 'correo' para evitar cuentas duplicadas.
-- =====================================================================
CREATE TABLE usuario (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    correo         VARCHAR(100) NOT NULL,
    password_hash  CHAR(64)     NOT NULL, -- SHA-256 con salt 'correo:clave'
    activo         TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_registro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso  DATETIME     NULL,
    CONSTRAINT uq_usuario_correo UNIQUE (correo)
) ENGINE=InnoDB;

-- =====================================================================
-- 3) TABLA: usuario_rol (Relación N:M)
-- Resuelve la relación de muchos usuarios con muchos roles.
-- Llave primaria compuesta para impedir asignaciones repetidas.
-- =====================================================================
CREATE TABLE usuario_rol (
    id_usuario       INT NOT NULL,
    id_rol           INT NOT NULL,
    fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 4) TABLA: perfil (Relación 1:1 con usuario)
-- Garantizada mediante 'id_usuario' marcado como UNIQUE.
-- Almacena datos personales del usuario.
-- =====================================================================
CREATE TABLE perfil (
    id_perfil   INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario  INT NOT NULL,
    nombres     VARCHAR(60) NOT NULL,
    apellidos   VARCHAR(60) NOT NULL,
    documento   VARCHAR(20) NOT NULL,
    telefono    VARCHAR(20) NOT NULL,
    direccion   VARCHAR(150),
    foto        VARCHAR(255) DEFAULT 'default-avatar.png',
    CONSTRAINT uq_perfil_usuario   UNIQUE (id_usuario),
    CONSTRAINT uq_perfil_documento UNIQUE (documento),
    CONSTRAINT fk_perfil_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 5) TABLA: ciudad
-- Catálogo de ubicaciones geográficas de Colombia.
-- =====================================================================
CREATE TABLE ciudad (
    id_ciudad    INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL,
    departamento VARCHAR(60) NOT NULL,
    activo       TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT uq_ciudad_nombre_depto UNIQUE (nombre, departamento)
) ENGINE=InnoDB;

-- =====================================================================
-- 6) TABLA: tipo_propiedad
-- Catálogo de tipos de inmuebles (Casa, Apartamento, Local, etc.).
-- =====================================================================
CREATE TABLE tipo_propiedad (
    id_tipo     INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),
    activo      TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT uq_tipo_propiedad_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- =====================================================================
-- 7) TABLA: propiedad
-- Núcleo del negocio inmobiliario.
-- Restricción UNIQUE obligatoria en 'matricula_inmobiliaria' y 'codigo'.
-- Llave foránea a ciudad, tipo_propiedad y usuario (agente responsable).
-- =====================================================================
CREATE TABLE propiedad (
    id_propiedad          INT AUTO_INCREMENT PRIMARY KEY,
    codigo                VARCHAR(20)    NOT NULL,
    matricula_inmobiliaria VARCHAR(30)   NOT NULL,
    titulo                VARCHAR(120)   NOT NULL,
    descripcion           TEXT           NOT NULL,
    precio                DECIMAL(14,2)  NOT NULL,
    tipo_negocio          ENUM('VENTA','ARRIENDO') NOT NULL DEFAULT 'VENTA',
    direccion             VARCHAR(150)   NOT NULL,
    id_ciudad             INT            NOT NULL,
    id_tipo               INT            NOT NULL,
    id_agente             INT            NOT NULL,
    area_m2               DECIMAL(8,2)   NOT NULL,
    habitaciones          INT            NOT NULL DEFAULT 0,
    banos                 INT            NOT NULL DEFAULT 0,
    parqueaderos          INT            NOT NULL DEFAULT 0,
    estrato               INT            NOT NULL DEFAULT 3,
    estado                ENUM('DISPONIBLE','RESERVADA','VENDIDA','ARRENDADA','INACTIVA')
                          NOT NULL DEFAULT 'DISPONIBLE',
    destacada             TINYINT(1)     NOT NULL DEFAULT 0,
    fecha_publicacion     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo                TINYINT(1)     NOT NULL DEFAULT 1,
    CONSTRAINT uq_propiedad_codigo    UNIQUE (codigo),
    CONSTRAINT uq_propiedad_matricula UNIQUE (matricula_inmobiliaria),
    CONSTRAINT fk_propiedad_ciudad FOREIGN KEY (id_ciudad)
        REFERENCES ciudad(id_ciudad) ON UPDATE CASCADE,
    CONSTRAINT fk_propiedad_tipo FOREIGN KEY (id_tipo)
        REFERENCES tipo_propiedad(id_tipo) ON UPDATE CASCADE,
    CONSTRAINT fk_propiedad_agente FOREIGN KEY (id_agente)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 8) TABLA: imagen_propiedad (Relación 1:N con propiedad)
-- Una propiedad posee una galería de imágenes.
-- Si la propiedad se borra, sus imágenes asociadas se eliminan en cascada.
-- =====================================================================
CREATE TABLE imagen_propiedad (
    id_imagen    INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad INT NOT NULL,
    url_imagen   VARCHAR(255) NOT NULL,
    titulo       VARCHAR(100),
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    orden        INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_imagen_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedad(id_propiedad) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 9) TABLA: caracteristica
-- Amenidades y bondades (Piscina, Ascensor, Gimnasio, etc.).
-- =====================================================================
CREATE TABLE caracteristica (
    id_caracteristica INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(60) NOT NULL,
    icono             VARCHAR(50) DEFAULT 'bi-check2-circle',
    activo            TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT uq_caracteristica_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- =====================================================================
-- 10) TABLA: propiedad_caracteristica (Relación N:M)
-- Vincula múltiples características a cada propiedad con datos propios (valor).
-- =====================================================================
CREATE TABLE propiedad_caracteristica (
    id_propiedad      INT NOT NULL,
    id_caracteristica INT NOT NULL,
    valor             VARCHAR(50) DEFAULT 'Sí',
    PRIMARY KEY (id_propiedad, id_caracteristica),
    CONSTRAINT fk_pc_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedad(id_propiedad) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pc_caracteristica FOREIGN KEY (id_caracteristica)
        REFERENCES caracteristica(id_caracteristica) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 11) TABLA: cita
-- Agendamiento de visitas presenciales.
-- Restricción UNIQUE compuesta (id_propiedad, fecha_hora) para impedir
-- que se agenden dos visitas a la misma propiedad en el mismo horario.
-- =====================================================================
CREATE TABLE cita (
    id_cita        INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad   INT NOT NULL,
    id_cliente     INT NOT NULL,
    id_agente      INT NOT NULL,
    fecha_hora     DATETIME NOT NULL,
    mensaje        TEXT,
    estado         ENUM('SOLICITADA','CONFIRMADA','REALIZADA','CANCELADA')
                   NOT NULL DEFAULT 'SOLICITADA',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cita_propiedad_fecha_hora UNIQUE (id_propiedad, fecha_hora),
    CONSTRAINT fk_cita_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedad(id_propiedad) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cita_cliente FOREIGN KEY (id_cliente)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE,
    CONSTRAINT fk_cita_agente FOREIGN KEY (id_agente)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 12) TABLA: solicitud
-- Trámite formal de compra o arriendo radicado por un cliente.
-- =====================================================================
CREATE TABLE solicitud (
    id_solicitud       INT AUTO_INCREMENT PRIMARY KEY,
    codigo             VARCHAR(20)    NOT NULL,
    id_propiedad       INT            NOT NULL,
    id_cliente         INT            NOT NULL,
    tipo_solicitud     ENUM('COMPRA','ARRIENDO') NOT NULL,
    oferta_precio      DECIMAL(14,2)  NOT NULL,
    ingresos_mensuales DECIMAL(14,2)  NOT NULL,
    mensaje            TEXT,
    estado             ENUM('PENDIENTE','EN_REVISION','APROBADA','RECHAZADA')
                       NOT NULL DEFAULT 'PENDIENTE',
    fecha_solicitud    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta    DATETIME       NULL,
    observaciones      TEXT,
    CONSTRAINT uq_solicitud_codigo UNIQUE (codigo),
    CONSTRAINT fk_solicitud_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedad(id_propiedad) ON UPDATE CASCADE,
    CONSTRAINT fk_solicitud_cliente FOREIGN KEY (id_cliente)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 13) TABLA: documento_solicitud (1:N con solicitud)
-- Radicación de soportes y documentación del cliente.
-- =====================================================================
CREATE TABLE documento_solicitud (
    id_documento   INT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud   INT NOT NULL,
    tipo_documento VARCHAR(80) NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    fecha_subida   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_documento_solicitud FOREIGN KEY (id_solicitud)
        REFERENCES solicitud(id_solicitud) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 14) TABLA: favorito
-- Marcador de propiedades de interés para clientes.
-- UNIQUE compuesta (id_usuario, id_propiedad) para evitar duplicados.
-- =====================================================================
CREATE TABLE favorito (
    id_favorito    INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario     INT NOT NULL,
    id_propiedad   INT NOT NULL,
    fecha_agregado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_favorito_usuario_propiedad UNIQUE (id_usuario, id_propiedad),
    CONSTRAINT fk_favorito_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_favorito_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedad(id_propiedad) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 15) TABLA: auditoria (Trazabilidad)
-- =====================================================================
CREATE TABLE auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario   INT NULL,
    accion       VARCHAR(50) NOT NULL,
    modulo       VARCHAR(50) NOT NULL,
    detalle      TEXT,
    fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_origen    VARCHAR(45),
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =====================================================================
-- POBLADO DE DATOS DE PRUEBA (MÍNIMO 10 REGISTROS POR TABLA PRINCIPAL)
-- Clave general de prueba para todos los usuarios: "1234"
-- Cifrada mediante SHA-256 usando salt: CONCAT(correo, ':1234')
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) ROLES (3 roles del sistema)
-- ---------------------------------------------------------------------
INSERT INTO rol (id_rol, nombre, descripcion, activo) VALUES
(1, 'ADMIN',   'Acceso total a configuración, catálogos, usuarios y auditoría', 1),
(2, 'AGENTE',  'Inmobiliaria: publica y edita propiedades, fotos, citas y solicitudes', 1),
(3, 'CLIENTE', 'Explora, agenda visitas, marca favoritos y radica solicitudes', 1);

-- ---------------------------------------------------------------------
-- 2) USUARIOS (12 usuarios: 2 Administradores, 4 Agentes, 6 Clientes)
-- Clave: 1234
-- ---------------------------------------------------------------------
INSERT INTO usuario (id_usuario, correo, password_hash, activo, fecha_registro) VALUES
-- Administradores
(1, 'admin@horizonte.com',   SHA2('admin@horizonte.com:1234', 256),   1, '2026-01-10 08:00:00'),
(2, 'sistemas@horizonte.com', SHA2('sistemas@horizonte.com:1234', 256), 1, '2026-01-11 09:30:00'),
-- Agentes inmobiliarios
(3, 'carlos.agente@horizonte.com',  SHA2('carlos.agente@horizonte.com:1234', 256),  1, '2026-01-15 10:00:00'),
(4, 'maria.agente@horizonte.com',   SHA2('maria.agente@horizonte.com:1234', 256),   1, '2026-01-16 11:00:00'),
(5, 'javier.agente@horizonte.com',  SHA2('javier.agente@horizonte.com:1234', 256),  1, '2026-01-20 14:00:00'),
(6, 'diana.agente@horizonte.com',   SHA2('diana.agente@horizonte.com:1234', 256),   1, '2026-01-22 15:30:00'),
-- Clientes
(7,  'juan.perez@gmail.com',    SHA2('juan.perez@gmail.com:1234', 256),    1, '2026-02-01 08:15:00'),
(8,  'andrea.gomez@gmail.com',  SHA2('andrea.gomez@gmail.com:1234', 256),  1, '2026-02-03 09:45:00'),
(9,  'felipe.torres@gmail.com', SHA2('felipe.torres@gmail.com:1234', 256), 1, '2026-02-05 14:20:00'),
(10, 'laura.castro@gmail.com',  SHA2('laura.castro@gmail.com:1234', 256),  1, '2026-02-10 16:10:00'),
(11, 'sergio.rojas@gmail.com',  SHA2('sergio.rojas@gmail.com:1234', 256),  1, '2026-02-12 11:25:00'),
(12, 'valentina.mora@gmail.com',SHA2('valentina.mora@gmail.com:1234', 256), 1, '2026-02-15 17:00:00');

-- ---------------------------------------------------------------------
-- 3) USUARIO_ROL (Asignación N:M)
-- ---------------------------------------------------------------------
INSERT INTO usuario_rol (id_usuario, id_rol) VALUES
(1, 1), -- Admin
(2, 1), -- Admin
(3, 2), -- Agente
(4, 2), -- Agente
(5, 2), -- Agente
(6, 2), -- Agente
(7, 3), -- Cliente
(8, 3), -- Cliente
(9, 3), -- Cliente
(10, 3),-- Cliente
(11, 3),-- Cliente
(12, 3);-- Cliente

-- ---------------------------------------------------------------------
-- 4) PERFIL (1:1 con usuario)
-- ---------------------------------------------------------------------
INSERT INTO perfil (id_usuario, nombres, apellidos, documento, telefono, direccion, foto) VALUES
(1,  'Julián',    'Barney',   '1098123401', '3157890123', 'Calle 35 # 28-15, Bucaramanga', 'avatar1.png'),
(2,  'Andrés',    'Salgado',  '1098123402', '3168901234', 'Carrera 27 # 45-20, Floridablanca', 'avatar2.png'),
(3,  'Carlos',    'Mendoza',  '1098123403', '3179012345', 'Av. González Valencia # 52-10', 'avatar3.png'),
(4,  'María',     'Herrera',  '1098123404', '3180123456', 'Calle 48 # 33-80, Cabecera', 'avatar4.png'),
(5,  'Javier',    'Suárez',   '1098123405', '3191234567', 'Carrera 19 # 35-12, Centro', 'avatar5.png'),
(6,  'Diana',     'Paredes',  '1098123406', '3102345678', 'Transversal Oriental # 89-40', 'avatar6.png'),
(7,  'Juan José', 'Pérez',    '1098123407', '3113456789', 'Calle 56 # 14-22, Bucaramanga', 'avatar7.png'),
(8,  'Andrea',    'Gómez',    '1098123408', '3124567890', 'Calle 105 # 23-45, Provenza', 'avatar8.png'),
(9,  'Felipe',    'Torres',   '1098123409', '3135678901', 'Carrera 33 # 48-15, Cabecera', 'avatar9.png'),
(10, 'Laura',     'Castro',   '1098123410', '3146789012', 'Anillo Vial # 12-40, Girón', 'avatar10.png'),
(11, 'Sergio',    'Rojas',    '1098123411', '3157890124', 'Autopista Floridablanca # 85-30', 'avatar11.png'),
(12, 'Valentina', 'Mora',     '1098123412', '3168901235', 'Calle 9 # 18-50, Piedecuesta', 'avatar12.png');

-- ---------------------------------------------------------------------
-- 5) CIUDAD (10 ciudades de Colombia)
-- ---------------------------------------------------------------------
INSERT INTO ciudad (id_ciudad, nombre, departamento, activo) VALUES
(1,  'Bucaramanga',    'Santander',            1),
(2,  'Floridablanca',  'Santander',            1),
(3,  'Girón',          'Santander',            1),
(4,  'Piedecuesta',    'Santander',            1),
(5,  'Bogotá D.C.',    'Cundinamarca',         1),
(6,  'Medellín',       'Antioquia',            1),
(7,  'Cali',           'Valle del Cauca',      1),
(8,  'Barranquilla',   'Atlántico',            1),
(9,  'Cartagena',      'Bolívar',              1),
(10, 'Santa Marta',    'Magdalena',            1);

-- ---------------------------------------------------------------------
-- 6) TIPO_PROPIEDAD (10 tipos de inmuebles)
-- ---------------------------------------------------------------------
INSERT INTO tipo_propiedad (id_tipo, nombre, descripcion, activo) VALUES
(1,  'Apartamento',      'Unidad habitacional en conjunto o edificio residencial', 1),
(2,  'Casa Campestre',   'Vivienda unifamiliar amplia con amplias zonas verdes', 1),
(3,  'Casa Urbana',      'Vivienda unifamiliar ubicada en zona céntrica o residencial', 1),
(4,  'Penthouse',        'Exclusivo apartamento en el último piso con terraza panorámica', 1),
(5,  'Local Comercial',  'Espacio adecuado para almacenes, comercio o restaurantes', 1),
(6,  'Oficina',          'Espacio corporativo profesional en centro empresarial', 1),
(7,  'Bodega / Galpón',  'Inmueble industrial para almacenamiento o logística pesada', 1),
(8,  'Lote / Terreno',   'Terreno urbanizable para desarrollo comercial o residencial', 1),
(9,  'Finca Productiva', 'Predio rural destinado al agro, descanso o producción', 1),
(10, 'Consultorio',      'Espacio acondicionado para atención médica u odontológica', 1);

-- ---------------------------------------------------------------------
-- 7) CARACTERISTICA (10 características/amenidades)
-- ---------------------------------------------------------------------
INSERT INTO caracteristica (id_caracteristica, nombre, icono, activo) VALUES
(1,  'Piscina',               'bi-water',          1),
(2,  'Gimnasio dotado',       'bi-activity',       1),
(3,  'Ascensor de última gen', 'bi-arrow-up-circle',1),
(4,  'Parqueadero visitantes', 'bi-p-circle',       1),
(5,  'Vigilancia 24/7',       'bi-shield-check',   1),
(6,  'Balcón con vista',      'bi-binoculars',     1),
(7,  'Zona BBQ y terraza',    'bi-fire',           1),
(8,  'Zona infantil',         'bi-emoji-smile',    1),
(9,  'Circuito cerrado TV',   'bi-camera-video',   1),
(10, 'Cancha múltiple',       'bi-trophy',         1);

-- ---------------------------------------------------------------------
-- 8) PROPIEDAD (10 inmuebles con matrículas y datos reales)
-- ---------------------------------------------------------------------
INSERT INTO propiedad (
    id_propiedad, codigo, matricula_inmobiliaria, titulo, descripcion,
    precio, tipo_negocio, direccion, id_ciudad, id_tipo, id_agente,
    area_m2, habitaciones, banos, parqueaderos, estrato, estado, destacada, fecha_publicacion, activo
) VALUES
(1, 'INM-001', 'MAT-300-100201', 'Apartamento de Lujo en Cabecera',
 'Hermoso apartamento con acabados italianos, vista panorámica sobre la meseta de Bucaramanga y cocina abierta de cuarzo.',
 580000000.00, 'VENTA', 'Cra. 35 # 52-24 Apto 1202', 1, 1, 3, 128.50, 3, 3, 2, 6, 'DISPONIBLE', 1, '2026-02-01 10:00:00', 1),

(2, 'INM-002', 'MAT-300-100202', 'Casa Campestre en Ruitoque Condominio',
 'Espectacular casa campestre con piscina privada, clima fresco, jardines zen y vista inigualable al cañón.',
 1650000000.00, 'VENTA', 'Condominio Ruitoque Golf Club Parcela 45', 2, 2, 4, 450.00, 4, 5, 4, 6, 'DISPONIBLE', 1, '2026-02-02 11:30:00', 1),

(3, 'INM-003', 'MAT-300-100203', 'Apartamento Familiar en Cañaveral',
 'Excelente ubicación cerca a centros comerciales La Florida y Caracolí. Cómodo, ventilado e iluminado.',
 2800000.00, 'ARRIENDO', 'Calle 31 # 26-18 Torre 2 Apto 804', 2, 1, 3, 92.00, 3, 2, 1, 4, 'DISPONIBLE', 1, '2026-02-03 09:15:00', 1),

(4, 'INM-004', 'MAT-300-100204', 'Penthouse Exclusivo con Terraza en Provenza',
 'Penthouse dúplex con terraza de 40m2, jacuzzi privado, zona BBQ y automatización domótica total.',
 890000000.00, 'VENTA', 'Calle 105 # 24-50 PH 1801', 1, 4, 5, 210.00, 4, 4, 2, 5, 'DISPONIBLE', 1, '2026-02-05 14:00:00', 1),

(5, 'INM-005', 'MAT-300-100205', 'Local Comercial en Plaza Central Girón',
 'Local en esquina de alto tráfico peatonal y vehicular, ideal para franquicias bancarias, retail o café gourmet.',
 6500000.00, 'ARRIENDO', 'Calle 30 # 25-04 Esquina', 3, 5, 6, 115.00, 0, 2, 0, 4, 'DISPONIBLE', 0, '2026-02-06 16:45:00', 1),

(6, 'INM-006', 'MAT-300-100206', 'Oficina Corporativa en Centro Empresarial',
 'Oficina amoblada con divisiones en vidrio templado, sala de juntas, recepción y aire acondicionado central.',
 3900000.00, 'ARRIENDO', 'Carrera 27 # 36-14 Of. 705', 1, 6, 4, 85.00, 2, 2, 2, 5, 'DISPONIBLE', 0, '2026-02-08 10:20:00', 1),

(7, 'INM-007', 'MAT-300-100207', 'Casa Tradicional en San Francisco',
 'Amplia casa de dos plantas con garaje doble, patio interior colonial y potencial para uso mixto o residencial.',
 420000000.00, 'VENTA', 'Carrera 22 # 18-35', 1, 3, 5, 230.00, 5, 3, 2, 3, 'DISPONIBLE', 0, '2026-02-10 12:00:00', 1),

(8, 'INM-008', 'MAT-300-100208', 'Bodega Industrial en Parque Logístico Chimita',
 'Bodega de triple altura con muelle de carga, piso de alta resistencia, subestación eléctrica y oficinas.',
 18000000.00, 'ARRIENDO', 'Parque Industrial Chimita Manzana B Lote 8', 3, 7, 6, 750.00, 3, 4, 6, 4, 'DISPONIBLE', 0, '2026-02-11 15:10:00', 1),

(9, 'INM-009', 'MAT-300-100209', 'Lote Urbanizable en Piedecuesta Guatiguará',
 'Excelente topografía semi-plana con disponibilidad de servicios públicos, ideal para condominio campestre.',
 750000000.00, 'VENTA', 'Vereda Guatiguará Sector El Trapiche', 4, 8, 3, 2800.00, 0, 0, 0, 3, 'DISPONIBLE', 1, '2026-02-12 11:00:00', 1),

(10, 'INM-010', 'MAT-300-100210', 'Finca de Descanso en Mesa de los Santos',
 'Hermosa finca cafetera con casa en tapia pisada restaurada, árboles frutales, kiosco de asados y sendero.',
 980000000.00, 'VENTA', 'Vereda El Tabacal Sector Acapulco', 4, 9, 4, 5200.00, 4, 3, 8, 3, 'DISPONIBLE', 1, '2026-02-14 09:30:00', 1);

-- ---------------------------------------------------------------------
-- 9) IMAGEN_PROPIEDAD (1:N con propiedad - Galería de imágenes)
-- ---------------------------------------------------------------------
INSERT INTO imagen_propiedad (id_propiedad, url_imagen, titulo, es_principal, orden) VALUES
(1, 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800', 'Sala Comedor Vista Panorámica', 1, 1),
(1, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800', 'Cocina Integral de Cuarzo', 0, 2),
(2, 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800', 'Fachada y Piscina Iluminada', 1, 1),
(2, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800', 'Jardines Exteriores y Terraza', 0, 2),
(3, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800', 'Apartamento Sala Iluminada', 1, 1),
(4, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800', 'Penthouse Terraza Privada', 1, 1),
(5, 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800', 'Local Vitrina Comercial', 1, 1),
(6, 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800', 'Oficina Espacio Abierto y Recepción', 1, 1),
(7, 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800', 'Casa Frente y Jardín Frontal', 1, 1),
(8, 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800', 'Bodega Triple Altura Nave Central', 1, 1),
(9, 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800', 'Lote Vista Panorámica Terreno', 1, 1),
(10, 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=800', 'Finca Casa Tradicional y Kiosco', 1, 1);

-- ---------------------------------------------------------------------
-- 10) PROPIEDAD_CARACTERISTICA (N:M)
-- ---------------------------------------------------------------------
INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, valor) VALUES
(1, 1, 'Climatizada'),
(1, 2, 'Dotación profesional'),
(1, 3, 'Doble ascensor'),
(1, 5, '24 Horas'),
(1, 6, '18 m2'),
(2, 1, 'Privada sin fin'),
(2, 5, 'Monitoreada'),
(2, 7, 'Kiosco con horno de leña'),
(3, 1, 'Social'),
(3, 8, 'Canchas y juegos'),
(4, 1, 'Privada y jacuzzi'),
(4, 6, 'Terraza 40 m2'),
(4, 7, 'Parrilla argentina'),
(6, 3, 'Ascensor inteligente'),
(6, 9, 'Circuito IP'),
(7, 5, 'Alarma comunitaria');

-- ---------------------------------------------------------------------
-- 11) CITA (Mínimo 10 citas agendadas)
-- Con UNIQUE (id_propiedad, fecha_hora)
-- ---------------------------------------------------------------------
INSERT INTO cita (id_propiedad, id_cliente, id_agente, fecha_hora, mensaje, estado, fecha_creacion) VALUES
(1, 7,  3, '2026-03-01 10:00:00', 'Deseo conocer la distribución y los parqueaderos.', 'CONFIRMADA', '2026-02-15 08:30:00'),
(1, 8,  3, '2026-03-02 15:00:00', 'Interesada en compra inmediata por crédito hipotecario.', 'SOLICITADA', '2026-02-16 10:00:00'),
(2, 9,  4, '2026-03-03 09:30:00', 'Visita familiar para ver la casa campestre en Ruitoque.', 'CONFIRMADA', '2026-02-17 11:20:00'),
(3, 10, 3, '2026-03-04 11:00:00', 'Revisión del inmueble para arriendo con aseguradora.', 'CONFIRMADA', '2026-02-18 14:00:00'),
(4, 11, 5, '2026-03-05 16:30:00', 'Quiero ver el estado de la terraza y el jacuzzi.', 'SOLICITADA', '2026-02-19 16:15:00'),
(5, 12, 6, '2026-03-06 10:30:00', 'Visita técnica con arquitecto para adecuar restaurante.', 'CONFIRMADA', '2026-02-20 09:40:00'),
(6, 7,  4, '2026-03-07 14:00:00', 'Verificar cableado estructurado y parqueaderos.', 'REALIZADA',  '2026-02-21 15:00:00'),
(7, 8,  5, '2026-03-08 09:00:00', 'Conocer la distribución de los 5 cuartos.', 'REALIZADA',  '2026-02-22 17:10:00'),
(8, 9,  6, '2026-03-09 11:30:00', 'Inspección de piso y altura libre de bodega.', 'CANCELADA',  '2026-02-23 08:50:00'),
(10, 10, 4, '2026-03-10 10:00:00', 'Recorrido por la finca cafetera y fuentes de agua.', 'SOLICITADA', '2026-02-24 13:25:00');

-- ---------------------------------------------------------------------
-- 12) SOLICITUD (Mínimo 10 solicitudes de compra / arriendo)
-- ---------------------------------------------------------------------
INSERT INTO solicitud (
    id_solicitud, codigo, id_propiedad, id_cliente, tipo_solicitud,
    oferta_precio, ingresos_mensuales, mensaje, estado, fecha_solicitud, fecha_respuesta, observaciones
) VALUES
(1,  'SOL-2026-001', 1, 7,  'COMPRA',   570000000.00, 22000000.00, 'Ofrezco pago de contado el 60% y crédito aprobado.', 'APROBADA',    '2026-02-16 09:00:00', '2026-02-18 10:00:00', 'Documentos verificados exitosamente con el banco.'),
(2,  'SOL-2026-002', 3, 8,  'ARRIENDO',   2800000.00, 11000000.00, 'Solicitud de arrendamiento con póliza de Sura.',       'APROBADA',    '2026-02-17 11:30:00', '2026-02-19 14:00:00', 'Aseguradora emitió concepto favorable.'),
(3,  'SOL-2026-003', 2, 9,  'COMPRA',  1600000000.00, 45000000.00, 'Propuesta comercial con permuta de apartamento menor.', 'EN_REVISION', '2026-02-18 15:20:00', NULL, 'En estudio de avalúo de la permuta.'),
(4,  'SOL-2026-004', 4, 10, 'COMPRA',   870000000.00, 28000000.00, 'Oferta con crédito preaprobado Bancolombia.',           'PENDIENTE',   '2026-02-20 10:15:00', NULL, NULL),
(5,  'SOL-2026-005', 5, 11, 'ARRIENDO',   6000000.00, 25000000.00, 'Contrato a 3 años para cadena de farmacias.',           'EN_REVISION', '2026-02-21 16:40:00', NULL, 'Revisión de estados financieros corporativos.'),
(6,  'SOL-2026-006', 6, 12, 'ARRIENDO',   3700000.00, 15000000.00, 'Empresa de desarrollo de software busca sede.',        'APROBADA',    '2026-02-22 09:10:00', '2026-02-24 11:00:00', 'Contrato listo para firma digital.'),
(7,  'SOL-2026-007', 7, 7,  'COMPRA',   400000000.00, 18000000.00, 'Oferta de compra para remodelación.',                  'RECHAZADA',   '2026-02-23 14:00:00', '2026-02-25 09:30:00', 'Propietario no aceptó valor por debajo del avalúo.'),
(8,  'SOL-2026-008', 8, 8,  'ARRIENDO',  17000000.00, 60000000.00, 'Arriendo para centro de distribución metropolitano.',    'PENDIENTE',   '2026-02-24 10:45:00', NULL, NULL),
(9,  'SOL-2026-009', 9, 9,  'COMPRA',   720000000.00, 35000000.00, 'Oferta para compra de lote con fiducia.',               'PENDIENTE',   '2026-02-25 11:20:00', NULL, NULL),
(10, 'SOL-2026-010', 10, 10, 'COMPRA',  950000000.00, 30000000.00, 'Interés en finca para proyecto agroturístico.',         'EN_REVISION', '2026-02-26 15:30:00', NULL, 'Verificando linderos con el IGAC.');

-- ---------------------------------------------------------------------
-- 13) DOCUMENTO_SOLICITUD (Soportes radicados)
-- ---------------------------------------------------------------------
INSERT INTO documento_solicitud (id_solicitud, tipo_documento, nombre_archivo) VALUES
(1, 'Cédula de Ciudadanía', 'doc_cc_juan_perez.pdf'),
(1, 'Carta Laboral',        'doc_laboral_juan_perez.pdf'),
(1, 'Extractos Bancarios',  'doc_extractos_juan_perez.pdf'),
(2, 'Cédula de Ciudadanía', 'doc_cc_andrea_gomez.pdf'),
(2, 'Certificación Ingresos','doc_ingresos_andrea_gomez.pdf'),
(3, 'RUT Persona Jurídica', 'doc_rut_felipe_torres.pdf'),
(4, 'Preaprobado Bancario', 'doc_banco_laura_castro.pdf'),
(5, 'Cámara de Comercio',   'doc_camara_comercio_corp.pdf'),
(6, 'Extractos Bancarios',  'doc_extractos_valentina.pdf'),
(7, 'Cédula de Ciudadanía', 'doc_cc_juan_perez_2.pdf');

-- ---------------------------------------------------------------------
-- 14) FAVORITO (Mínimo 10 marcaciones)
-- Con UNIQUE (id_usuario, id_propiedad)
-- ---------------------------------------------------------------------
INSERT INTO favorito (id_usuario, id_propiedad) VALUES
(7, 1),
(7, 2),
(8, 3),
(8, 4),
(9, 2),
(9, 9),
(10, 1),
(10, 4),
(11, 5),
(12, 10);

-- =====================================================================
-- CONSULTAS DE VERIFICACIÓN
-- =====================================================================
-- Conteo de tablas creadas:
-- SELECT COUNT(*) AS total_tablas FROM information_schema.tables WHERE table_schema = 'inmobiliaria_db';
--
-- Usuarios y roles:
-- SELECT u.id_usuario, u.correo, p.nombres, p.apellidos, r.nombre AS rol
-- FROM usuario u
-- JOIN perfil p ON p.id_usuario = u.id_usuario
-- JOIN usuario_rol ur ON ur.id_usuario = u.id_usuario
-- JOIN rol r ON r.id_rol = ur.id_rol
-- ORDER BY u.id_usuario;
