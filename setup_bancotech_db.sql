-- ============================================================================
-- BANCOTECH - SISTEMA BANCARIO VULNERABLE
-- ============================================================================
-- ADVERTENCIA: Base de datos con vulnerabilidades INTENCIONALES
-- Para fines educativos - Práctica de auditoría y stress testing
-- ============================================================================

DROP DATABASE IF EXISTS bancotech_db;
CREATE DATABASE bancotech_db;

\c bancotech_db;

-- ============================================================================
-- TABLAS PRINCIPALES
-- ============================================================================

-- Tabla de clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    ciudad VARCHAR(100),
    fecha_nacimiento DATE,
    numero_identificacion VARCHAR(20) UNIQUE,  -- VULNERABLE: sin encriptar
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de credenciales (VULNERABLE: contraseñas en texto plano)
CREATE TABLE credenciales (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,  -- TEXTO PLANO
    pin VARCHAR(4),  -- PIN en texto plano
    ultimo_acceso TIMESTAMP,
    intentos_fallidos INTEGER DEFAULT 0
);

-- Tabla de cuentas bancarias
CREATE TABLE cuentas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    numero_cuenta VARCHAR(20) UNIQUE NOT NULL,  -- VULNERABLE: predecible
    tipo_cuenta VARCHAR(20),  -- 'Ahorro', 'Corriente', 'Inversión'
    saldo DECIMAL(15, 2) DEFAULT 0.00,  -- VULNERABLE: sin validación
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(20) DEFAULT 'Activa',  -- 'Activa', 'Bloqueada', 'Cerrada'
    limite_transferencia DECIMAL(15, 2) DEFAULT 999999.99  -- VULNERABLE: muy alto
);

-- Tabla de transacciones (SIN ÍNDICES para forzar performance)
CREATE TABLE transacciones (
    id BIGSERIAL PRIMARY KEY,
    cuenta_origen_id INTEGER REFERENCES cuentas(id),
    cuenta_destino_id INTEGER REFERENCES cuentas(id),
    tipo_transaccion VARCHAR(30),  -- 'Transferencia', 'Depósito', 'Retiro', 'Pago'
    monto DECIMAL(15, 2) NOT NULL,
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'Completada',  -- 'Pendiente', 'Completada', 'Rechazada'
    ip_origen INET,  -- VULNERABLE: logs sin protección
    dispositivo VARCHAR(100)
);

-- Tabla de tarjetas (VULNERABLE: datos sin encriptar)
CREATE TABLE tarjetas (
    id SERIAL PRIMARY KEY,
    cuenta_id INTEGER REFERENCES cuentas(id),
    numero_tarjeta VARCHAR(16) NOT NULL,  -- SIN ENCRIPTAR
    cvv VARCHAR(3),  -- SIN ENCRIPTAR
    fecha_expiracion VARCHAR(7),
    tipo VARCHAR(20),  -- 'Débito', 'Crédito'
    limite_credito DECIMAL(15, 2),
    estado VARCHAR(20) DEFAULT 'Activa'
);

-- Tabla de préstamos
CREATE TABLE prestamos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    monto_prestamo DECIMAL(15, 2) NOT NULL,
    tasa_interes DECIMAL(5, 2),
    plazo_meses INTEGER,
    monto_mensual DECIMAL(15, 2),
    saldo_pendiente DECIMAL(15, 2),
    fecha_inicio DATE,
    estado VARCHAR(20) DEFAULT 'Activo'
);

-- Tabla de empleados del banco
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    puesto VARCHAR(50),
    salario DECIMAL(10, 2),  -- VULNERABLE: visible
    sucursal VARCHAR(100),
    fecha_contratacion DATE,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de credenciales de empleados (VULNERABLE)
CREATE TABLE credenciales_empleados (
    id SERIAL PRIMARY KEY,
    empleado_id INTEGER REFERENCES empleados(id),
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,  -- TEXTO PLANO
    rol VARCHAR(30),  -- 'admin', 'cajero', 'gerente', 'soporte'
    permisos TEXT  -- VULNERABLE: permisos en texto
);

-- ============================================================================
-- INSERCIÓN DE DATOS DE PRUEBA (MASIVOS PARA FORZAR VM)
-- ============================================================================

-- Insertar 5,000 clientes
INSERT INTO clientes (nombre, apellido, email, telefono, direccion, ciudad, fecha_nacimiento, numero_identificacion)
SELECT 
    'Cliente' || i,
    'Apellido' || i,
    'cliente' || i || '@email.com',
    '555-' || LPAD(i::TEXT, 7, '0'),
    'Calle ' || i || ' #' || (i * 10),
    CASE (i % 15)
        WHEN 0 THEN 'Ciudad de México'
        WHEN 1 THEN 'Guadalajara'
        WHEN 2 THEN 'Monterrey'
        WHEN 3 THEN 'Puebla'
        WHEN 4 THEN 'Tijuana'
        WHEN 5 THEN 'León'
        WHEN 6 THEN 'Querétaro'
        WHEN 7 THEN 'Mérida'
        WHEN 8 THEN 'Cancún'
        WHEN 9 THEN 'Toluca'
        WHEN 10 THEN 'Aguascalientes'
        WHEN 11 THEN 'Chihuahua'
        WHEN 12 THEN 'Hermosillo'
        WHEN 13 THEN 'Veracruz'
        ELSE 'Oaxaca'
    END,
    DATE '1960-01-01' + (i || ' days')::INTERVAL,
    'ID' || LPAD(i::TEXT, 10, '0')
FROM generate_series(1, 5000) AS i;

-- Insertar credenciales (VULNERABLES)
INSERT INTO credenciales (cliente_id, username, password, pin)
SELECT 
    id,
    'user' || id,
    'password' || id,  -- Contraseñas predecibles
    LPAD((id % 10000)::TEXT, 4, '0')  -- PINs predecibles
FROM clientes;

-- Insertar 7,000 cuentas (algunos clientes tienen múltiples cuentas)
INSERT INTO cuentas (cliente_id, numero_cuenta, tipo_cuenta, saldo)
SELECT 
    (RANDOM() * 4999 + 1)::INTEGER,
    '1000' || LPAD(i::TEXT, 12, '0'),  -- Números predecibles
    CASE (i % 3)
        WHEN 0 THEN 'Ahorro'
        WHEN 1 THEN 'Corriente'
        ELSE 'Inversión'
    END,
    (RANDOM() * 100000)::DECIMAL(15, 2)  -- Saldos aleatorios
FROM generate_series(1, 7000) AS i;

-- Insertar 50,000 transacciones (FORZAR PERFORMANCE)
INSERT INTO transacciones (cuenta_origen_id, cuenta_destino_id, tipo_transaccion, monto, descripcion, fecha, ip_origen)
SELECT 
    (RANDOM() * 6999 + 1)::INTEGER,
    (RANDOM() * 6999 + 1)::INTEGER,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Transferencia'
        WHEN 1 THEN 'Depósito'
        ELSE 'Retiro'
    END,
    (RANDOM() * 10000 + 10)::DECIMAL(15, 2),
    'Transacción ' || i,
    CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL,
    ('192.168.' || (RANDOM() * 255)::INTEGER || '.' || (RANDOM() * 255)::INTEGER)::INET
FROM generate_series(1, 50000) AS i;

-- Insertar tarjetas (VULNERABLES)
INSERT INTO tarjetas (cuenta_id, numero_tarjeta, cvv, fecha_expiracion, tipo, limite_credito)
SELECT 
    id,
    '4' || LPAD((id * 1000000000000)::TEXT, 15, '0'),  -- Números predecibles
    LPAD((id % 1000)::TEXT, 3, '0'),  -- CVV predecible
    TO_CHAR(CURRENT_DATE + INTERVAL '2 years', 'MM/YYYY'),
    CASE (id % 2)
        WHEN 0 THEN 'Débito'
        ELSE 'Crédito'
    END,
    CASE 
        WHEN id % 2 = 1 THEN (RANDOM() * 50000 + 10000)::DECIMAL(15, 2)
        ELSE NULL
    END
FROM cuentas
WHERE id <= 5000;

-- Insertar préstamos
INSERT INTO prestamos (cliente_id, monto_prestamo, tasa_interes, plazo_meses, monto_mensual, saldo_pendiente, fecha_inicio)
SELECT 
    (RANDOM() * 4999 + 1)::INTEGER,
    (RANDOM() * 500000 + 50000)::DECIMAL(15, 2),
    (RANDOM() * 10 + 5)::DECIMAL(5, 2),
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 12
        WHEN 1 THEN 24
        ELSE 36
    END,
    (RANDOM() * 10000 + 1000)::DECIMAL(15, 2),
    (RANDOM() * 400000 + 40000)::DECIMAL(15, 2),
    CURRENT_DATE - (RANDOM() * 730 || ' days')::INTERVAL
FROM generate_series(1, 2000) AS i;

-- Insertar empleados
INSERT INTO empleados (nombre, apellido, email, puesto, salario, sucursal, fecha_contratacion)
VALUES
('Juan', 'Administrador', 'admin@bancotech.com', 'Director General', 80000.00, 'Matriz', '2015-01-15'),
('María', 'Gerente', 'maria.gerente@bancotech.com', 'Gerente Sucursal', 45000.00, 'Sucursal Centro', '2018-03-20'),
('Pedro', 'Cajero', 'pedro.cajero@bancotech.com', 'Cajero', 18000.00, 'Sucursal Norte', '2020-06-10'),
('Ana', 'Soporte', 'ana.soporte@bancotech.com', 'Soporte Técnico', 25000.00, 'Matriz', '2019-08-15'),
('Luis', 'Auditor', 'luis.auditor@bancotech.com', 'Auditor Interno', 35000.00, 'Matriz', '2017-11-01');

-- Insertar credenciales de empleados (VULNERABLES)
INSERT INTO credenciales_empleados (empleado_id, username, password, rol, permisos)
VALUES
(1, 'admin', 'admin123', 'admin', 'ALL'),
(2, 'gerente', 'gerente2024', 'gerente', 'READ,WRITE,APPROVE'),
(3, 'cajero', 'cajero123', 'cajero', 'READ,TRANSACTIONS'),
(4, 'soporte', 'soporte', 'soporte', 'READ'),
(5, 'auditor', 'audit2024', 'auditor', 'READ,AUDIT');

-- ============================================================================
-- USUARIOS DE BASE DE DATOS (VULNERABLES)
-- ============================================================================

CREATE USER bancotech_app WITH PASSWORD 'banco123';
GRANT ALL PRIVILEGES ON DATABASE bancotech_db TO bancotech_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bancotech_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bancotech_app;

CREATE USER bancotech_readonly WITH PASSWORD 'readonly';
GRANT CONNECT ON DATABASE bancotech_db TO bancotech_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bancotech_readonly;

-- ============================================================================
-- FUNCIONES VULNERABLES
-- ============================================================================

-- Función vulnerable a race conditions
CREATE OR REPLACE FUNCTION transferir_fondos(
    p_cuenta_origen INTEGER,
    p_cuenta_destino INTEGER,
    p_monto DECIMAL
) RETURNS BOOLEAN AS $$
DECLARE
    v_saldo_origen DECIMAL;
BEGIN
    -- VULNERABLE: No usa locks, permite race conditions
    SELECT saldo INTO v_saldo_origen FROM cuentas WHERE id = p_cuenta_origen;
    
    -- Simular delay para aumentar probabilidad de race condition
    PERFORM pg_sleep(0.1);
    
    IF v_saldo_origen >= p_monto THEN
        UPDATE cuentas SET saldo = saldo - p_monto WHERE id = p_cuenta_origen;
        UPDATE cuentas SET saldo = saldo + p_monto WHERE id = p_cuenta_destino;
        
        INSERT INTO transacciones (cuenta_origen_id, cuenta_destino_id, tipo_transaccion, monto)
        VALUES (p_cuenta_origen, p_cuenta_destino, 'Transferencia', p_monto);
        
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MENSAJE FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'BANCOTECH - BASE DE DATOS CREADA EXITOSAMENTE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Sistema bancario con vulnerabilidades intencionales';
    RAISE NOTICE '';
    RAISE NOTICE 'Estadísticas:';
    RAISE NOTICE '  - 5,000 clientes';
    RAISE NOTICE '  - 7,000 cuentas bancarias';
    RAISE NOTICE '  - 50,000 transacciones';
    RAISE NOTICE '  - 5,000 tarjetas';
    RAISE NOTICE '  - 2,000 préstamos';
    RAISE NOTICE '';
    RAISE NOTICE 'VULNERABILIDADES INCLUIDAS:';
    RAISE NOTICE '  - Contraseñas y PINs en texto plano';
    RAISE NOTICE '  - Datos de tarjetas sin encriptar';
    RAISE NOTICE '  - Race conditions en transferencias';
    RAISE NOTICE '  - Números de cuenta predecibles';
    RAISE NOTICE '  - Sin límites de transferencia';
    RAISE NOTICE '  - Falta de índices (performance issues)';
    RAISE NOTICE '  - Logs sin protección';
    RAISE NOTICE '';
    RAISE NOTICE 'Usuarios de BD:';
    RAISE NOTICE '  - bancotech_app (password: banco123)';
    RAISE NOTICE '  - bancotech_readonly (password: readonly)';
    RAISE NOTICE '';
    RAISE NOTICE '¡Listo para auditar!';
    RAISE NOTICE '============================================================================';
END $$;
