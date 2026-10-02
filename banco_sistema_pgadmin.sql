-- =============================================================================
-- MÁSTER EN BIG DATA Y CIENCIA DE DATOS - VIU
-- ASIGNATURA: Herramientas de Bases de Datos (17MBID)
-- ACTIVIDAD: Diseño e Implementación de Base de Datos para el Sistema Bancario
-- AUTOR: Juan David Ortiz Encarnación
-- SCRIPT: Creación de Esquema, Inserción y Consultas SQL para PostgreSQL / pgAdmin
-- =============================================================================

-- INSTRUCCIÓN PARA pgADMIN:
-- 1. Abre pgAdmin y conéctate a tu servidor PostgreSQL.
-- 2. Crea una base de datos llamada 'banco_sistema' (o usa la base de datos por defecto 'postgres').
-- 3. Abre la herramienta de consulta (Tools > Query Tool) sobre dicha base de datos.
-- 4. Pega y ejecuta este script completo (F5).

-- =============================================================================
-- 1. DDL: LIMPIEZA PREVIA Y CREACIÓN DE TIPOS / TABLAS
-- =============================================================================

-- Eliminación ordenada de tablas previas (con CASCADE para evitar conflictos de FKs)
DROP TABLE IF EXISTS pago CASCADE;
DROP TABLE IF EXISTS cliente_prestamo CASCADE;
DROP TABLE IF EXISTS prestamo CASCADE;
DROP TABLE IF EXISTS cliente_cuenta CASCADE;
DROP TABLE IF EXISTS cuenta_corriente CASCADE;
DROP TABLE IF EXISTS cuenta_ahorro CASCADE;
DROP TABLE IF EXISTS cuenta CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;
DROP TABLE IF EXISTS dependiente CASCADE;
DROP TABLE IF EXISTS empleado CASCADE;
DROP TABLE IF EXISTS sucursal CASCADE;
DROP TYPE IF EXISTS tipo_cuenta_enum CASCADE;
DROP VIEW IF EXISTS vista_empleado CASCADE;

-- Tipo Enumerado nativo de PostgreSQL para los tipos de cuenta
CREATE TYPE tipo_cuenta_enum AS ENUM ('AHORRO', 'CORRIENTE');

-- -----------------------------------------------------------------------------
-- Tabla 1: SUCURSAL
-- -----------------------------------------------------------------------------
CREATE TABLE sucursal (
    nombre_sucursal VARCHAR(50) NOT NULL,
    localidad VARCHAR(100) NOT NULL,
    activos NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_sucursal PRIMARY KEY (nombre_sucursal),
    CONSTRAINT chk_sucursal_activos CHECK (activos >= 0)
);

-- -----------------------------------------------------------------------------
-- Tabla 2: EMPLEADO
-- Relación reflexiva (id_jefe) para la jerarquía de supervisión.
-- -----------------------------------------------------------------------------
CREATE TABLE empleado (
    id_empleado INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    id_jefe INT NULL,
    CONSTRAINT pk_empleado PRIMARY KEY (id_empleado),
    CONSTRAINT fk_empleado_jefe FOREIGN KEY (id_jefe)
        REFERENCES empleado (id_empleado)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- En PostgreSQL, los campos calculados dinámicamente dependientes de la fecha actual 
-- (CURRENT_DATE) se encapsulan formalmente mediante una VISTA para respetar la 1FN
-- sin almacenar redundancias en disco:
CREATE OR REPLACE VIEW vista_empleado AS
SELECT 
    id_empleado,
    nombre,
    telefono,
    fecha_contratacion,
    id_jefe,
    EXTRACT(YEAR FROM age(CURRENT_DATE, fecha_contratacion))::INT AS antiguedad_anios
FROM empleado;

-- -----------------------------------------------------------------------------
-- Tabla 3: DEPENDIENTE (Entidad débil de EMPLEADO)
-- PK compuesta: (id_empleado, nombre_dependiente)
-- -----------------------------------------------------------------------------
CREATE TABLE dependiente (
    id_empleado INT NOT NULL,
    nombre_dependiente VARCHAR(100) NOT NULL,
    parentesco VARCHAR(50) NULL,
    CONSTRAINT pk_dependiente PRIMARY KEY (id_empleado, nombre_dependiente),
    CONSTRAINT fk_dependiente_empleado FOREIGN KEY (id_empleado)
        REFERENCES empleado (id_empleado)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- Tabla 4: CLIENTE
-- Relación N:1 con Empleado (Asesor Personal)
-- -----------------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    calle VARCHAR(150) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    id_empleado_asesor INT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT fk_cliente_asesor FOREIGN KEY (id_empleado_asesor)
        REFERENCES empleado (id_empleado)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- Tabla 5: CUENTA (Superentidad de la jerarquía ISA)
-- -----------------------------------------------------------------------------
CREATE TABLE cuenta (
    id_cuenta INT NOT NULL,
    saldo NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    tipo_cuenta tipo_cuenta_enum NOT NULL,
    CONSTRAINT pk_cuenta PRIMARY KEY (id_cuenta)
);

-- -----------------------------------------------------------------------------
-- Tabla 6: CUENTA_AHORRO (Especialización ISA)
-- -----------------------------------------------------------------------------
CREATE TABLE cuenta_ahorro (
    id_cuenta INT NOT NULL,
    tasa_interes NUMERIC(5, 2) NOT NULL,
    CONSTRAINT pk_cuenta_ahorro PRIMARY KEY (id_cuenta),
    CONSTRAINT fk_cuenta_ahorro_cuenta FOREIGN KEY (id_cuenta)
        REFERENCES cuenta (id_cuenta)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_tasa_interes CHECK (tasa_interes >= 0)
);

-- -----------------------------------------------------------------------------
-- Tabla 7: CUENTA_CORRIENTE (Especialización ISA)
-- -----------------------------------------------------------------------------
CREATE TABLE cuenta_corriente (
    id_cuenta INT NOT NULL,
    descubierto NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_cuenta_corriente PRIMARY KEY (id_cuenta),
    CONSTRAINT fk_cuenta_corriente_cuenta FOREIGN KEY (id_cuenta)
        REFERENCES cuenta (id_cuenta)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_descubierto CHECK (descubierto >= 0)
);

-- -----------------------------------------------------------------------------
-- Tabla 8: CLIENTE_CUENTA (Relación N:M entre Cliente y Cuenta)
-- Atributo propio: fecha_ultimo_acceso
-- -----------------------------------------------------------------------------
CREATE TABLE cliente_cuenta (
    id_cliente INT NOT NULL,
    id_cuenta INT NOT NULL,
    fecha_ultimo_acceso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_cliente_cuenta PRIMARY KEY (id_cliente, id_cuenta),
    CONSTRAINT fk_cliente_cuenta_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_cliente_cuenta_cuenta FOREIGN KEY (id_cuenta)
        REFERENCES cuenta (id_cuenta)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- Tabla 9: PRESTAMO (Relación 1:N con Sucursal)
-- -----------------------------------------------------------------------------
CREATE TABLE prestamo (
    id_prestamo INT NOT NULL,
    importe NUMERIC(12, 2) NOT NULL,
    nombre_sucursal VARCHAR(50) NOT NULL,
    CONSTRAINT pk_prestamo PRIMARY KEY (id_prestamo),
    CONSTRAINT fk_prestamo_sucursal FOREIGN KEY (nombre_sucursal)
        REFERENCES sucursal (nombre_sucursal)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_prestamo_importe CHECK (importe > 0)
);

-- -----------------------------------------------------------------------------
-- Tabla 10: CLIENTE_PRESTAMO (Relación N:M entre Cliente y Préstamo)
-- Admite cotitularidades
-- -----------------------------------------------------------------------------
CREATE TABLE cliente_prestamo (
    id_cliente INT NOT NULL,
    id_prestamo INT NOT NULL,
    CONSTRAINT pk_cliente_prestamo PRIMARY KEY (id_cliente, id_prestamo),
    CONSTRAINT fk_cliente_prestamo_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_cliente_prestamo_prestamo FOREIGN KEY (id_prestamo)
        REFERENCES prestamo (id_prestamo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- Tabla 11: PAGO (Entidad débil de PRESTAMO)
-- PK compuesta: (id_prestamo, numero_pago)
-- -----------------------------------------------------------------------------
CREATE TABLE pago (
    id_prestamo INT NOT NULL,
    numero_pago INT NOT NULL,
    fecha_pago DATE NOT NULL,
    importe NUMERIC(12, 2) NOT NULL,
    CONSTRAINT pk_pago PRIMARY KEY (id_prestamo, numero_pago),
    CONSTRAINT fk_pago_prestamo FOREIGN KEY (id_prestamo)
        REFERENCES prestamo (id_prestamo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_pago_importe CHECK (importe > 0)
);


-- =============================================================================
-- 2. DML: INSERCIÓN DE DATOS DE PRUEBA
-- =============================================================================

-- Sucursales
INSERT INTO sucursal (nombre_sucursal, localidad, activos) VALUES
('Central Madrid', 'Madrid', 50000000.00),
('Diagonal Barcelona', 'Barcelona', 35000000.00),
('Gran Vía Valencia', 'Valencia', 22000000.00),
('Nervión Sevilla', 'Sevilla', 18000000.00),
('Zabalburu Bilbao', 'Bilbao', 15000000.00);

-- Empleados
INSERT INTO empleado (id_empleado, nombre, telefono, fecha_contratacion, id_jefe) VALUES
(101, 'Carlos Mendoza', '611223344', '2015-03-01', NULL),
(102, 'Elena Sánchez',  '622334455', '2018-06-15', 101),
(103, 'Javier Torres',  '633445566', '2020-01-10', 101),
(104, 'Marta Ruiz',     '644556677', '2021-09-01', 102),
(105, 'Sergio Ramos',   '655667788', '2022-04-20', 102),
(106, 'Lucía Navarro',  '666778899', '2023-11-15', 103);

-- Dependientes
INSERT INTO dependiente (id_empleado, nombre_dependiente, parentesco) VALUES
(101, 'Marcos Mendoza', 'Hijo'),
(101, 'Sofia Mendoza',  'Hija'),
(102, 'Daniel Gil',     'Hijo'),
(104, 'Mateo Ruiz',     'Hijo');

-- Clientes
INSERT INTO cliente (id_cliente, nombre, calle, ciudad, id_empleado_asesor) VALUES
(1, 'Antonio Alcántara',  'Calle San Genaro 12',     'Madrid',    102),
(2, 'Mercedes Fernández', 'Calle Mayor 45',          'Madrid',    102),
(3, 'Joan Rovira',        'Passeig de Gràcia 88',    'Barcelona', 104),
(4, 'Carmen Morales',     'Calle Sierpes 15',        'Sevilla',   105),
(5, 'Iker Echeverría',    'Gran Vía D. Diego 3',     'Bilbao',    103),
(6, 'Raquel Gómez',       'Calle Colón 22',          'Valencia',  NULL);

-- Cuentas (Superentidad)
INSERT INTO cuenta (id_cuenta, saldo, tipo_cuenta) VALUES
(1001, 15400.50, 'AHORRO'),
(1002,  2350.00, 'CORRIENTE'),
(1003, 45000.00, 'AHORRO'),
(1004,   850.75, 'CORRIENTE'),
(1005,  7200.00, 'AHORRO'),
(1006,  1200.00, 'CORRIENTE');

-- Subtipos: Cuentas de Ahorro
INSERT INTO cuenta_ahorro (id_cuenta, tasa_interes) VALUES
(1001, 2.75),
(1003, 3.50),
(1005, 1.90);

-- Subtipos: Cuentas Corrientes
INSERT INTO cuenta_corriente (id_cuenta, descubierto) VALUES
(1002, 1000.00),
(1004,  500.00),
(1006, 1500.00);

-- Titularidades de Cuentas (N:M)
INSERT INTO cliente_cuenta (id_cliente, id_cuenta, fecha_ultimo_acceso) VALUES
(1, 1001, '2026-09-28 10:15:00'),
(1, 1002, '2026-10-01 09:30:00'),
(2, 1002, '2026-09-30 18:45:00'),
(3, 1003, '2026-09-25 14:20:00'),
(4, 1004, '2026-10-02 08:00:00'),
(5, 1005, '2026-09-15 11:10:00'),
(6, 1006, '2026-09-29 17:05:00');

-- Préstamos
INSERT INTO prestamo (id_prestamo, importe, nombre_sucursal) VALUES
(201, 120000.00, 'Central Madrid'),
(202,  45000.00, 'Diagonal Barcelona'),
(203,  15000.00, 'Nervión Sevilla'),
(204,  80000.00, 'Gran Vía Valencia');

-- Titulares de Préstamos (N:M con Cotitularidad)
INSERT INTO cliente_prestamo (id_cliente, id_prestamo) VALUES
(1, 201),
(2, 201),
(3, 202),
(4, 203),
(6, 204);

-- Pagos de Préstamo (Entidad débil)
INSERT INTO pago (id_prestamo, numero_pago, fecha_pago, importe) VALUES
(201, 1, '2026-06-05', 1250.00),
(201, 2, '2026-07-05', 1250.00),
(201, 3, '2026-08-05', 1250.00),
(202, 1, '2026-07-15',  650.00),
(202, 2, '2026-08-15',  650.00),
(203, 1, '2026-08-01',  400.00),
(204, 1, '2026-09-10',  980.00);


-- =============================================================================
-- 3. DQL: CONSULTAS SELECT DE COMPROBACIÓN
-- =============================================================================

SELECT * FROM sucursal;
SELECT * FROM vista_empleado; -- Vista con la antigüedad calculada
SELECT * FROM dependiente;
SELECT * FROM cliente;
SELECT * FROM cuenta;
SELECT * FROM cuenta_ahorro;
SELECT * FROM cuenta_corriente;
SELECT * FROM cliente_cuenta;
SELECT * FROM prestamo;
SELECT * FROM cliente_prestamo;
SELECT * FROM pago;


-- =============================================================================
-- 4. DQL: CONSULTAS DE INTERSECCIÓN (Requisito Académico)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CONSULTA 1: INTERSECCIÓN NATIVA CON EL OPERADOR INTERSECT
-- Obtiene los clientes que tienen tanto una cuenta como un préstamo concedido.
-- -----------------------------------------------------------------------------
SELECT c.id_cliente, c.nombre, c.ciudad
FROM cliente c
INNER JOIN cliente_cuenta cc ON c.id_cliente = cc.id_cliente

INTERSECT

SELECT c.id_cliente, c.nombre, c.ciudad
FROM cliente c
INNER JOIN cliente_prestamo cp ON c.id_cliente = cp.id_cliente;


-- -----------------------------------------------------------------------------
-- CONSULTA 2: INTERSECCIÓN MULTITABLA CON INNER JOIN (Cruce total)
-- Muestra el detalle completo del cruce: Cliente, su cuenta y su préstamo.
-- -----------------------------------------------------------------------------
SELECT 
    c.id_cliente,
    c.nombre AS nombre_cliente,
    cu.id_cuenta,
    cu.tipo_cuenta,
    cu.saldo,
    p.id_prestamo,
    p.importe AS importe_prestamo,
    p.nombre_sucursal
FROM cliente c
INNER JOIN cliente_cuenta cc   ON c.id_cliente = cc.id_cliente
INNER JOIN cuenta cu           ON cc.id_cuenta = cu.id_cuenta
INNER JOIN cliente_prestamo cp ON c.id_cliente = cp.id_cliente
INNER JOIN prestamo p          ON cp.id_prestamo = p.id_prestamo
ORDER BY c.id_cliente, cu.id_cuenta;


-- -----------------------------------------------------------------------------
-- CONSULTA 3: INTERSECCIÓN DE ESPECIALIZACIONES ISA
-- Clientes que tienen simultáneamente al menos una Cuenta de Ahorro y una Corriente.
-- -----------------------------------------------------------------------------
SELECT c.id_cliente, c.nombre
FROM cliente c
INNER JOIN cliente_cuenta cc ON c.id_cliente = cc.id_cliente
INNER JOIN cuenta_ahorro ca  ON cc.id_cuenta = ca.id_cuenta

INTERSECT

SELECT c.id_cliente, c.nombre
FROM cliente c
INNER JOIN cliente_cuenta cc ON c.id_cliente = cc.id_cliente
INNER JOIN cuenta_corriente cco ON cc.id_cuenta = cco.id_cuenta;


-- =============================================================================
-- 5. DML: OPERACIONES CRUD COMPLETAS (Update y Delete demostrativos)
-- =============================================================================

-- [U - UPDATE 1]: Actualización de saldo tras un depósito bancario
UPDATE cuenta 
SET saldo = saldo + 1500.00 
WHERE id_cuenta = 1001;

-- [U - UPDATE 2]: Reasignación de asesor personal a un cliente
UPDATE cliente 
SET id_empleado_asesor = 104 
WHERE id_cliente = 6;

-- [D - DELETE 1]: Cancelación/eliminación de un pago puntual
DELETE FROM pago 
WHERE id_prestamo = 201 AND numero_pago = 3;

-- [D - DELETE 2]: Demostración de Integridad Referencial con ON DELETE CASCADE
-- Al eliminar el préstamo 204, se eliminan automáticamente sus cotitulares en 
-- cliente_prestamo y sus pagos asociados en pago, sin dejar registros huérfanos.
DELETE FROM prestamo 
WHERE id_prestamo = 204;

-- Comprobación final tras operaciones de actualización y borrado:
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001;
SELECT id_cliente, nombre, id_empleado_asesor FROM cliente WHERE id_cliente = 6;
SELECT * FROM pago WHERE id_prestamo = 201;
SELECT * FROM prestamo WHERE id_prestamo = 204;

