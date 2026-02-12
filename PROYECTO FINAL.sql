-- 1. CLIENTE
create database AndreyLP;
use AndreyLP;


CREATE TABLE cliente (
    id_cliente INT NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_cliente)
);

-- 2. CORREO CLIENTE (múltiples correos por cliente)
CREATE TABLE correo_cliente (
    id_correo INT NOT NULL,
    id_cliente INT NOT NULL,
    correo VARCHAR(100) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_correo),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- 3. TELÉFONO CLIENTE (múltiples teléfonos por cliente)
CREATE TABLE telefono_cliente (
    id_telefono INT NOT NULL,
    id_cliente INT NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_telefono),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- 4. ROL
CREATE TABLE rol (
    id_rol INT NOT NULL,
    nombre_rol VARCHAR(50) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_rol),
    UNIQUE (nombre_rol)
);

-- 5. PERMISO
CREATE TABLE permiso (
    id_permiso INT NOT NULL,
    nombre_permiso VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_permiso),
    UNIQUE (nombre_permiso)
);

-- 6. ROL_PERMISO (relación muchos a muchos)
CREATE TABLE rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
    FOREIGN KEY (id_permiso) REFERENCES permiso(id_permiso)
);

-- 7. USUARIO (vinculado a cliente y rol)
CREATE TABLE usuario (
    id_usuario INT NOT NULL,
    id_cliente INT NOT NULL,
    id_rol INT NOT NULL,
    correo_usuario VARCHAR(100) NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_usuario),
    UNIQUE (correo_usuario),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
);

-- 8. CATEGORÍA
CREATE TABLE categoria (
    id_categoria INT NOT NULL,
    nombre_categoria VARCHAR(100) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_categoria)
);

-- 9. MARCA
CREATE TABLE marca (
    id_marca INT NOT NULL,
    nombre_marca VARCHAR(100) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_marca)
);

-- 10. PRODUCTO
CREATE TABLE producto (
    id_producto INT NOT NULL,
    id_categoria INT NOT NULL,
    id_marca INT NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_producto),
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    FOREIGN KEY (id_marca) REFERENCES marca(id_marca)
);

-- 11. PEDIDO
CREATE TABLE pedido (
    id_pedido INT NOT NULL,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'pagado', 'enviado', 'entregado') DEFAULT 'pendiente',
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_pedido),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- 12. DETALLE_PEDIDO
CREATE TABLE detalle_pedido (
    id_detalle INT NOT NULL,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_detalle),
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- 13. PAGO
CREATE TABLE pago (
    id_pago INT NOT NULL,
    id_pedido INT NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_pago),
    UNIQUE (id_pedido), -- Un pedido solo puede tener un pago
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
);

-- 14. ENVIO
CREATE TABLE envio (
    id_envio INT NOT NULL,
    id_pedido INT NOT NULL,
    direccion_envio VARCHAR(255) NOT NULL,
    transportadora VARCHAR(100) NOT NULL,
    fecha_envio DATETIME,
    fecha_estimada_entrega DATE,
    estado_entrega ENUM('preparando', 'en_transito', 'entregado', 'devuelto') DEFAULT 'preparando',
    activo TINYINT(1) DEFAULT 1,
    PRIMARY KEY (id_envio),
    UNIQUE (id_pedido), -- Un pedido solo tiene un envío
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
);

-- 1. Índice para buscar clientes activos por nombre
CREATE INDEX idx_cliente_nombre_activo
ON cliente(nombre_completo, activo);

-- 2. Índice para correos de clientes activos
CREATE INDEX idx_correo_cliente_activo
ON correo_cliente(id_cliente, activo);

-- 3. Índice para productos por categoría y marca
CREATE INDEX idx_producto_categoria_marca
ON producto(id_categoria, id_marca);

-- 4. Índice para pedidos por cliente y estado
CREATE INDEX idx_pedido_cliente_estado
ON pedido(id_cliente, estado);

-- 5. Índice para detalle_pedido por producto
CREATE INDEX idx_detalle_pedido_producto
ON detalle_pedido(id_producto);

-- 1. Vista de clientes activos con sus correos y teléfonos
CREATE VIEW vista_clientes_completa AS
SELECT c.id_cliente, c.nombre_completo, c.direccion,
       cc.correo, tc.telefono
FROM cliente c
LEFT JOIN correo_cliente cc ON c.id_cliente = cc.id_cliente AND cc.activo = 1
LEFT JOIN telefono_cliente tc ON c.id_cliente = tc.id_cliente AND tc.activo = 1
WHERE c.activo = 1;

-- 2. Vista de productos con su categoría y marca
CREATE VIEW vista_productos_completa AS
SELECT p.id_producto, p.nombre_producto, p.descripcion, p.precio, p.stock,
       c.nombre_categoria, m.nombre_marca
FROM producto p
JOIN categoria c ON p.id_categoria = c.id_categoria
JOIN marca m ON p.id_marca = m.id_marca
WHERE p.activo = 1;

-- 3. Vista de pedidos con total y estado
CREATE VIEW vista_pedidos_cliente AS
SELECT pe.id_pedido, pe.id_cliente, c.nombre_completo, pe.fecha_pedido,
       pe.estado, pe.total
FROM pedido pe
JOIN cliente c ON pe.id_cliente = c.id_cliente
WHERE pe.activo = 1;

-- 4. Vista de detalle de pedidos con productos
CREATE VIEW vista_detalle_pedidos AS
SELECT dp.id_detalle, dp.id_pedido, p.nombre_producto, dp.cantidad, dp.precio_unitario
FROM detalle_pedido dp
JOIN producto p ON dp.id_producto = p.id_producto
WHERE dp.activo = 1;

-- 5. Vista de pagos y envíos de pedidos
CREATE VIEW vista_pagos_envios AS
SELECT pe.id_pedido, p.metodo_pago, p.monto_pagado, e.transportadora, e.estado_entrega
FROM pedido pe
LEFT JOIN pago p ON pe.id_pedido = p.id_pedido
LEFT JOIN envio e ON pe.id_pedido = e.id_pedido
WHERE pe.activo = 1;


select * from pago;
