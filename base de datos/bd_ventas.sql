-- phpMyAdmin SQL Dump
-- Declaración de encabezado que indica que este archivo fue generado por phpMyAdmin

-- version 5.1.1
-- Versión de phpMyAdmin utilizada para generar el dump

-- https://www.phpmyadmin.net/
-- URL oficial de phpMyAdmin

--
-- Servidor: 127.0.0.1
-- Dirección IP del servidor de base de datos (localhost)

-- Tiempo de generación: 24-09-2022 a las 00:53:59
-- Fecha y hora en que se generó el archivo de volcado

-- Versión del servidor: 10.4.22-MariaDB
-- Versión del servidor de base de datos MariaDB

-- Versión de PHP: 7.4.27
-- Versión de PHP utilizada

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
-- Configura el modo SQL para evitar la asignación automática de valores en columnas AUTO_INCREMENT al insertar 0

START TRANSACTION;
-- Inicia una transacción para garantizar la integridad de las operaciones

SET time_zone = "+00:00";
-- Establece la zona horaria del servidor a UTC

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
-- Comentarios condicionales para MySQL que guardan configuraciones actuales y establecen UTF8 como conjunto de caracteres

--
-- Base de datos: `bd_ventas`
-- Nombre de la base de datos que se está volcando

DELIMITER $$
-- Cambia el delimitador de comandos de ; a $$ para permitir la creación de procedimientos almacenados

--
-- Procedimientos
-- Sección para crear procedimientos almacenados

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_precio_producto` (IN `n_cantidad` INT, IN `n_precio` DECIMAL(10,2), IN `codigo` INT)  BEGIN
-- Crea el procedimiento actualizar_precio_producto con 3 parámetros de entrada
    	DECLARE nueva_existencia int;
        DECLARE nuevo_total decimal(10,2);
        DECLARE nuevo_precio decimal(10,2);
        
        DECLARE cant_actual int;
        DECLARE pre_actual decimal(10,2);
        
        DECLARE actual_existencia int;
        DECLARE actual_precio decimal(10,2);
        -- Declara variables locales para los cálculos
        
        SELECT precio,existencia INTO actual_precio,actual_existencia FROM producto WHERE codproducto = codigo;
        -- Obtiene el precio y existencia actual del producto
        
        SET nueva_existencia = actual_existencia + n_cantidad;
        -- Calcula la nueva existencia sumando la cantidad recibida
        
        UPDATE producto SET existencia = nueva_existencia, precio = n_precio WHERE codproducto = codigo;
        -- Actualiza la existencia y precio del producto en la base de datos
        
        SELECT nueva_existencia,nuevo_precio;
        -- Devuelve los nuevos valores calculados
        
     END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp` (IN `codigo` INT, IN `cantidad` INT, IN `token_user` VARCHAR(50))  BEGIN
-- Crea el procedimiento add_detalle_temp para agregar productos al carrito temporal de ventas
    
    	DECLARE precio_actual decimal(10,2);
        DECLARE costo_actual decimal(10,2);
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para precio, costo y existencia
        
        SELECT costo,precio INTO costo_actual,precio_actual FROM producto WHERE codproducto = codigo;
        -- Obtiene el costo y precio del producto
        
        INSERT INTO detalle_temp(token_user,codproducto,cantidad,costo,precio_venta) VALUES(token_user,codigo,cantidad,costo_actual,precio_actual);
        -- Inserta el producto en la tabla temporal de detalles de venta
        
        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = codigo;
        -- Obtiene la existencia actual del producto

                SET nueva_existencia = existencia_actual - cantidad;
                -- Calcula la nueva existencia restando la cantidad vendida
                
                UPDATE producto SET existencia = nueva_existencia WHERE codproducto = codigo;
                -- Actualiza la existencia del producto en inventario
        
        SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
        INNER JOIN producto p 
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token_user;
        -- Devuelve los detalles del carrito temporal
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp_compra` (IN `codigo` INT, IN `cantidad` INT, IN `token_user` VARCHAR(50), IN `costo` DECIMAL(10,2))  BEGIN 
-- Crea el procedimiento add_detalle_temp_compra para agregar productos al carrito temporal de compras
	    DECLARE precio_actual decimal(10,2);
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para precio y existencia
        
        INSERT INTO detalle_temp_compra(token_user,codproducto,cantidad,precio_venta) VALUES(token_user,codigo,cantidad,costo);
        -- Inserta el producto en la tabla temporal de detalles de compra
        
        SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp_compra tmp
        INNER JOIN producto p 
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token_user;
        -- Devuelve los detalles del carrito temporal de compras
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_compra` (IN `no_venta` INT)  BEGIN
-- Crea el procedimiento anular_compra para revertir una compra registrada
	DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int;
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar el proceso de anulación
        
        SET existe_venta = (SELECT COUNT(*) FROM compras WHERE nocompra = no_venta and status != 2);
        -- Verifica si existe la compra y no está ya anulada
        
        IF existe_venta > 0 THEN
        -- Si la compra existe y no está anulada
        	CREATE TEMPORARY TABLE tbl_tmp (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar los productos de la compra
                
                SET a = 1;
                -- Inicializa contador
                
                SET registros = (SELECT COUNT(*)FROM entradas WHERE nocompra = no_venta);
                -- Cuenta cuántos productos hay en la compra
                
                IF registros > 0 THEN
                -- Si hay productos en la compra
                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM entradas WHERE nocompra = no_venta;
                    -- Copia los productos a la tabla temporal
                    
                    WHILE a <= registros DO
                    -- Itera por cada producto
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        -- Obtiene el código y cantidad del producto actual
                        
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        -- Obtiene la existencia actual del producto
                        
                        SET nueva_existencia = existencia_actual - cant_producto;
                        -- Calcula la nueva existencia restando lo comprado
                        
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        -- Actualiza el inventario del producto
                        
                        SET a=a+1;
                        -- Incrementa el contador
                    
                    END WHILE;
                    -- Fin del bucle
                    
                    UPDATE compras SET status = 2 WHERE nocompra = no_venta;
                    -- Marca la compra como anulada (status = 2)
                    
                    DROP TABLE tbl_tmp;
                    -- Elimina la tabla temporal
                    
                    SELECT * FROM compras WHERE nocompra = no_venta;
                    -- Devuelve la información de la compra anulada
                
                END IF;
                -- Fin del condicional de registros
        
        ELSE
        -- Si la compra no existe o ya está anulada
        	SELECT 0 compras;
            -- Devuelve 0 indicando que no se pudo anular
        END IF;
        -- Fin del condicional principal
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_venta` (IN `no_venta` INT)  BEGIN
-- Crea el procedimiento anular_venta para revertir una venta registrada
    	DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int;
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar el proceso de anulación
        
        SET existe_venta = (SELECT COUNT(*) FROM venta WHERE noventa = no_venta and status != 2);
        -- Verifica si existe la venta y no está ya anulada
        
        IF existe_venta > 0 THEN
        -- Si la venta existe y no está anulada
        	CREATE TEMPORARY TABLE tbl_tmp (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar los productos de la venta
                
                SET a = 1;
                -- Inicializa contador
                
                SET registros = (SELECT COUNT(*)FROM detalleventa WHERE noventa = no_venta);
                -- Cuenta cuántos productos hay en la venta
                
                IF registros > 0 THEN
                -- Si hay productos en la venta
                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalleventa WHERE noventa = no_venta;
                    -- Copia los productos a la tabla temporal
                    
                    WHILE a <= registros DO
                    -- Itera por cada producto
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        -- Obtiene el código y cantidad del producto actual
                        
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        -- Obtiene la existencia actual del producto
                        
                        SET nueva_existencia = existencia_actual + cant_producto;
                        -- Calcula la nueva existencia sumando lo vendido (devolviendo al inventario)
                        
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        -- Actualiza el inventario del producto
                        
                        UPDATE detalleventa SET status = 2 WHERE noventa = no_venta;
                        -- Marca el detalle de venta como anulado
                        
                        SET a=a+1;
                        -- Incrementa el contador
                    
                    END WHILE;
                    -- Fin del bucle
                    
                    UPDATE venta SET status = 2 WHERE noventa = no_venta;
                    -- Marca la venta como anulada (status = 2)
                    
                    DROP TABLE tbl_tmp;
                    -- Elimina la tabla temporal
                    
                    SELECT * FROM venta WHERE noventa = no_venta;
                    -- Devuelve la información de la venta anulada
                
                END IF;
                -- Fin del condicional de registros
        
        ELSE
        -- Si la venta no existe o ya está anulada
        	SELECT 0 venta;
            -- Devuelve 0 indicando que no se pudo anular
        END IF;
        -- Fin del condicional principal
    
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelar_compra` (IN `token` INT)  BEGIN
-- Crea el procedimiento cancelar_compra para cancelar una compra en proceso
    	DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int; 
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar el proceso de cancelación
        
        SET existe_venta = (SELECT COUNT(*) FROM detalle_temp_compra WHERE token_user = token);
        -- Verifica si hay productos en el carrito temporal de compras
        
        IF existe_venta > 0 THEN
        -- Si hay productos en el carrito
        	CREATE TEMPORARY TABLE tbl_tmp (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar los productos del carrito
                
                SET a = 1;
                -- Inicializa contador
                
                SET registros = (SELECT COUNT(*)FROM detalle_temp_compra WHERE token_user = token);
                -- Cuenta cuántos productos hay en el carrito
                
                IF registros > 0 THEN
                -- Si hay productos en el carrito
                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp_compra WHERE token_user = token;
                    -- Copia los productos a la tabla temporal
                    
                    WHILE a <= registros DO
                    -- Itera por cada producto
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        -- Obtiene el código y cantidad del producto actual
                        
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        -- Obtiene la existencia actual del producto
                        
                        SET nueva_existencia = existencia_actual + cant_producto;
                        -- Calcula la nueva existencia sumando lo que estaba en el carrito
                        
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        -- Actualiza el inventario del producto (restaura las cantidades)
                        
                        SET a=a+1;
                        -- Incrementa el contador
                    
                    END WHILE;
                    -- Fin del bucle
                    
       DELETE FROM detalle_temp_compra WHERE token_user = token;
       -- Elimina todos los registros del carrito temporal de compras
       
              DROP TABLE tbl_tmp;
              -- Elimina la tabla temporal
       
       SELECT * FROM detalle_temp_compra WHERE token_user = token;
       -- Devuelve los registros (debería estar vacío)
                
                END IF;
                -- Fin del condicional de registros
        
        ELSE
        -- Si no hay productos en el carrito
        	SELECT 0 detalle_temp_compra;
            -- Devuelve 0 indicando que no había nada que cancelar
        END IF;
        -- Fin del condicional principal
    
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelar_venta` (IN `token` INT)  BEGIN
-- Crea el procedimiento cancelar_venta para cancelar una venta en proceso
    	DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int; 
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar el proceso de cancelación
        
        SET existe_venta = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token);
        -- Verifica si hay productos en el carrito temporal de ventas
        
        IF existe_venta > 0 THEN
        -- Si hay productos en el carrito
        	CREATE TEMPORARY TABLE tbl_tmp (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar los productos del carrito
                
                SET a = 1;
                -- Inicializa contador
                
                SET registros = (SELECT COUNT(*)FROM detalle_temp WHERE token_user = token);
                -- Cuenta cuántos productos hay en el carrito
                
                IF registros > 0 THEN
                -- Si hay productos en el carrito
                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;
                    -- Copia los productos a la tabla temporal
                    
                    WHILE a <= registros DO
                    -- Itera por cada producto
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        -- Obtiene el código y cantidad del producto actual
                        
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        -- Obtiene la existencia actual del producto
                        
                        SET nueva_existencia = existencia_actual + cant_producto;
                        -- Calcula la nueva existencia sumando lo que estaba en el carrito
                        
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        -- Actualiza el inventario del producto (restaura las cantidades)
                        
                        SET a=a+1;
                        -- Incrementa el contador
                    
                    END WHILE;
                    -- Fin del bucle
                    
       DELETE FROM detalle_temp WHERE token_user = token;
       -- Elimina todos los registros del carrito temporal de ventas
       
              DROP TABLE tbl_tmp;
              -- Elimina la tabla temporal
       
       SELECT * FROM detalle_temp WHERE token_user = token;
       -- Devuelve los registros (debería estar vacío)
                
                END IF;
                -- Fin del condicional de registros
        
        ELSE
        -- Si no hay productos en el carrito
        	SELECT 0 detalle_temp;
            -- Devuelve 0 indicando que no había nada que cancelar
        END IF;
        -- Fin del condicional principal
    
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `dataDashboard` (IN `caja_id` INT)  BEGIN
-- Crea el procedimiento dataDashboard para obtener estadísticas del sistema para el dashboard
    	
        DECLARE usuarios int;
        DECLARE clientes int;
        DECLARE proveedores int;
        DECLARE productos int;
        DECLARE ventas decimal(10,2);
        DECLARE abonos decimal(10,2);
        DECLARE pagos decimal(10,2);
        DECLARE compra decimal(10,2);
        DECLARE cobrar decimal(10,2);
        DECLARE pagar decimal(10,2);
        DECLARE egreso decimal(10,2);
        DECLARE credito decimal(10,2);
        DECLARE inicios decimal(10,2);
        -- Declara variables para cada métrica del dashboard
        
        SELECT COUNT(*) INTO usuarios FROM usuario WHERE status !=10;
        -- Cuenta usuarios activos (status diferente de 10)
        
        SELECT COUNT(*) INTO clientes FROM cliente WHERE status !=10;
        -- Cuenta clientes activos
        
        SELECT COUNT(*) INTO proveedores FROM proveedor WHERE status !=10;
        -- Cuenta proveedores activos
        
        SELECT COUNT(*) INTO productos FROM producto WHERE status !=10;
        -- Cuenta productos activos
        
        SELECT SUM(totalventa) INTO ventas FROM venta WHERE caja = caja_id AND status =1;
        -- Suma total de ventas completadas en la caja específica
        
        SELECT SUM(totalventa) INTO credito FROM venta WHERE caja = caja_id AND status =3;
        -- Suma total de ventas a crédito en la caja específica
        
        SELECT SUM(cantidad) INTO abonos FROM detalle_recibo WHERE caja = caja_id;
        -- Suma total de abonos recibidos en la caja específica
        
        SELECT SUM(cantidad) INTO pagos FROM detalle_recibo_compra WHERE caja = caja_id;
        -- Suma total de pagos realizados en la caja específica
        
        SELECT SUM(totalcompra) INTO compra FROM compras WHERE caja = caja_id AND status =1;
        -- Suma total de compras completadas en la caja específica
        
        SELECT SUM(cantidad) INTO egreso FROM egresos WHERE caja = caja_id;
        -- Suma total de egresos en la caja específica
        
        SELECT SUM(totalventa-abono) INTO cobrar FROM venta WHERE status =3;
        -- Calcula el total por cobrar (ventas a crédito menos abonos)
        
        SELECT SUM(totalcompra-abono) INTO pagar FROM compras WHERE status =3;
        -- Calcula el total por pagar (compras a crédito menos abonos)
        
        SELECT inicio INTO inicios FROM caja WHERE status =1;
        -- Obtiene el monto inicial de la caja abierta
        
        SELECT usuarios,clientes,proveedores,productos,ventas,abonos,pagos,compra,cobrar,pagar,egreso,credito,inicios;
        -- Devuelve todas las métricas calculadas
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp` (IN `id_detalle` INT, IN `token` VARCHAR(50))  BEGIN    
-- Crea el procedimiento del_detalle_temp para eliminar un producto del carrito temporal de ventas
		DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int;
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar la eliminación

        	CREATE TEMPORARY TABLE tbl_tmp (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar el producto a eliminar
                
                SET a = 1;
                -- Inicializa contador
                
                SET registros = (SELECT COUNT(*)FROM detalle_temp WHERE correlativo = id_detalle);
                -- Verifica si existe el detalle específico

                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE correlativo = id_detalle;
                    -- Copia el producto a eliminar a la tabla temporal
                    
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        -- Obtiene el código y cantidad del producto
                        
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        -- Obtiene la existencia actual del producto
                        
                        SET nueva_existencia = existencia_actual + cant_producto;
                        -- Calcula la nueva existencia sumando la cantidad eliminada del carrito
                        
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        -- Actualiza el inventario del producto

            DELETE FROM detalle_temp WHERE correlativo = id_detalle;
            -- Elimina el producto del carrito temporal
  
            SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
            INNER JOIN producto p 
            ON tmp.codproducto = p.codproducto
            WHERE tmp.token_user = token;
            -- Devuelve los productos restantes en el carrito
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp_compra` (IN `id_detalle` INT, IN `token` VARCHAR(50))  BEGIN  	
-- Crea el procedimiento del_detalle_temp_compra para eliminar un producto del carrito temporal de compras
  		DECLARE existe_venta int;
        DECLARE registros int;
        DECLARE a int;
        
        DECLARE cod_producto int;
        DECLARE cant_producto int;
        DECLARE existencia_actual int;
        DECLARE nueva_existencia int;
        -- Declara variables para controlar la eliminación

        CREATE TEMPORARY TABLE tbl_tmp (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                -- Crea una tabla temporal para almacenar el producto a eliminar
                
                SET a = 1;
                -- Inicializa contador
                
         SET registros = (SELECT COUNT(*)FROM detalle_temp_compra WHERE correlativo = id_detalle);
                -- Verifica si existe el detalle específico

         INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp_compra WHERE correlativo = id_detalle;
                    -- Copia el producto a eliminar a la tabla temporal
                    
         SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                    -- Obtiene el código y cantidad del producto

            DELETE FROM detalle_temp_compra WHERE correlativo = id_detalle;
            -- Elimina el producto del carrito temporal de compras
  
            SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp_compra tmp
            INNER JOIN producto p 
            ON tmp.codproducto = p.codproducto
            WHERE tmp.token_user = token;
            -- Devuelve los productos restantes en el carrito de compras
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_compra` (IN `cod_usuario` INT, IN `cod_cliente` INT, IN `token` VARCHAR(50), IN `tipo_pago` INT, IN `id_caja` INT)  BEGIN
-- Crea el procedimiento procesar_compra para finalizar una compra
        DECLARE venta INT;
        
        DECLARE registros INT;        
        DECLARE total DECIMAL(10,2);
        
        DECLARE nueva_existencia int;
        DECLARE nuevo_costo DECIMAL(10,2);
        DECLARE nuevo_total DECIMAL(10,2);
        
        DECLARE existencia_actual int;
        DECLARE costo_actual DECIMAL(10,2);
        
        DECLARE tmp_cod_prod int;
        DECLARE tmp_cant_prod int;
        DECLARE tmp_cost_prod DECIMAL(10,2);
        DECLARE a INT;
        SET a = 1;
        -- Declara variables para procesar la compra
        
        CREATE TEMPORARY TABLE tbl_tmp_tokenuser(
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int,
                cost_prod DECIMAL(10,2));
                -- Crea tabla temporal para almacenar productos del carrito
                
SET registros = (SELECT COUNT(*) FROM detalle_temp_compra WHERE token_user = token);
        -- Cuenta los productos en el carrito de compras
        
        IF registros > 0 THEN
        -- Si hay productos en el carrito
  INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod,cost_prod) SELECT codproducto,cantidad,precio_venta FROM detalle_temp_compra WHERE token_user = token;
            -- Copia productos a tabla temporal
            
INSERT INTO compras(usuario,caja,codproveedor,status) VALUES(cod_usuario,id_caja,cod_cliente,tipo_pago);
            -- Crea registro de compra
            SET venta = LAST_INSERT_ID();
            -- Obtiene el ID de la compra creada
            
INSERT INTO entradas(nocompra,codproducto,cantidad,precio) SELECT(venta) as nocompra, codproducto,cantidad,precio_venta FROM detalle_temp_compra WHERE token_user = token;
            -- Registra los detalles de la compra en la tabla de entradas
            
            WHILE a <= registros DO
            -- Itera por cada producto
 SELECT cod_prod,cant_prod,cost_prod INTO tmp_cod_prod,tmp_cant_prod,tmp_cost_prod FROM tbl_tmp_tokenuser WHERE id = a;
       -- Obtiene datos del producto actual
       
 SELECT costo,existencia INTO costo_actual,existencia_actual FROM producto WHERE codproducto = tmp_cod_prod;
                -- Obtiene costo y existencia actual del producto
                
SET nueva_existencia = existencia_actual + tmp_cant_prod;
-- Calcula nueva existencia
SET nuevo_total = (existencia_actual * costo_actual) + (tmp_cant_prod * tmp_cost_prod);
-- Calcula nuevo valor total del inventario
SET nuevo_costo = nuevo_total / nueva_existencia;
-- Calcula nuevo costo promedio ponderado

UPDATE producto SET existencia = nueva_existencia,costo = nuevo_costo WHERE codproducto = tmp_cod_prod;
                -- Actualiza existencia y costo del producto
                
                SET a=a+1;
                -- Incrementa contador
           
            END WHILE;
            -- Fin del bucle
            
 SET total = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp_compra WHERE token_user = token);
-- Calcula total de la compra
UPDATE compras SET totalcompra = total WHERE nocompra = venta;
-- Actualiza total en registro de compra
DELETE FROM detalle_temp_compra WHERE token_user = token;
-- Limpia carrito temporal
            TRUNCATE TABLE tbl_tmp_tokenuser;
            -- Limpia tabla temporal
            SELECT * FROM compras WHERE nocompra = venta;
            -- Devuelve información de la compra procesada
            
        ELSE
        -- Si no hay productos en el carrito
            SELECT 0;
            -- Devuelve 0 indicando error
        END IF;
        -- Fin del condicional
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_venta` (IN `cod_usuario` INT, IN `cod_cliente` INT, IN `token` VARCHAR(50), IN `tipo_pago` INT, IN `id_caja` INT, IN `descuento` INT)  BEGIN
-- Crea el procedimiento procesar_venta para finalizar una venta
    	DECLARE venta INT;
        
        DECLARE registros INT;
        DECLARE subtotal DECIMAL(10,2);
        DECLARE total DECIMAL(10,2);
        
        DECLARE nueva_existencia int;
        DECLARE existencia_actual int;
        
        DECLARE tmp_cod_producto int;
        DECLARE tmp_cant_producto int;
        DECLARE a INT;
        SET a = 1;
        -- Declara variables para procesar la venta
        
        CREATE TEMPORARY TABLE tbl_tmp_tokenuser(
        		id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        		cod_prod BIGINT,
        		cant_prod int);
                -- Crea tabla temporal para almacenar productos del carrito
                
        SET registros = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token);
        -- Cuenta los productos en el carrito de ventas
        
        IF registros > 0 THEN
        -- Si hay productos en el carrito
        	INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;
            -- Copia productos a tabla temporal
            
            INSERT INTO venta(usuario,caja,codcliente,status,descuento) VALUES(cod_usuario,id_caja,cod_cliente,tipo_pago,descuento);
            -- Crea registro de venta
            SET venta = LAST_INSERT_ID();
            -- Obtiene el ID de la venta creada
            
            INSERT INTO detalleventa(noventa,codproducto,cantidad,costo,precio_venta) SELECT(venta) as noventa, codproducto,cantidad,costo,precio_venta FROM detalle_temp WHERE token_user = token;
            -- Registra los detalles de la venta
            
            WHILE a <= registros DO
            -- Itera por cada producto
            	SELECT cod_prod,cant_prod INTO tmp_cod_producto,tmp_cant_producto FROM tbl_tmp_tokenuser WHERE id = a;
                -- Obtiene datos del producto actual
                
                SET a=a+1;
                -- Incrementa contador
           
            END WHILE;
            -- Fin del bucle
            
            SET subtotal = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp WHERE token_user = token);
            -- Calcula subtotal de la venta
            SET total = subtotal - descuento;
            -- Calcula total con descuento
            UPDATE venta SET totalventa = total WHERE noventa = venta;
            -- Actualiza total en registro de venta
            DELETE FROM detalle_temp WHERE token_user = token;
            -- Limpia carrito temporal
            TRUNCATE TABLE tbl_tmp_tokenuser;
            -- Limpia tabla temporal
            SELECT * FROM venta WHERE noventa = venta;
            -- Devuelve información de la venta procesada
            
        ELSE
        -- Si no hay productos en el carrito
        	SELECT 0;
            -- Devuelve 0 indicando error
        END IF;
        -- Fin del condicional
    END$$

DELIMITER ;
-- Restablece el delimitador a su valor por defecto (;)

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja`
--

CREATE TABLE `caja` (
  `id` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `inicio` decimal(10,2) DEFAULT NULL,
  `ventas` decimal(10,2) DEFAULT NULL,
  `abonos` decimal(10,2) DEFAULT NULL,
  `egresos` decimal(10,2) DEFAULT NULL,
  `creditos` decimal(10,2) DEFAULT NULL,
  `total_efectivo` decimal(10,2) DEFAULT NULL,
  `usuario` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `nit` varchar(20) DEFAULT NULL,
  `nombre` varchar(80) DEFAULT NULL,
  `telefono` int(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `nit`, `nombre`, `telefono`, `direccion`, `date_add`, `usuario_id`, `status`) VALUES
(1, '6031807920003k', 'Cliente regular', 88888888, 'EL RAMA', '2021-12-05 15:47:39', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `nocompra` bigint(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `usuario` int(20) NOT NULL,
  `caja` int(11) NOT NULL,
  `codproveedor` int(20) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  `totalcompra` decimal(10,2) NOT NULL,
  `abono` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `id` bigint(20) NOT NULL,
  `nit` varchar(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `razon_social` varchar(100) NOT NULL,
  `telefono` bigint(20) NOT NULL,
  `email` varchar(200) NOT NULL,
  `direccion` text NOT NULL,
  `iva` decimal(10,2) NOT NULL,
  `foto` varchar(200) NOT NULL,
  `moneda` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `configuracion`
--

INSERT INTO `configuracion` (`id`, `nit`, `nombre`, `razon_social`, `telefono`, `email`, `direccion`, `iva`, `foto`, `moneda`) VALUES
(1, '6232912905005C', 'Lubricentro', 'Aceites y lubricantes', 85289255, 'lubricentro@gmail.com', 'Ciudad Rama', '0.00', ' ', '$');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalleventa`
--

CREATE TABLE `detalleventa` (
  `correlativo` bigint(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `noventa` bigint(11) DEFAULT NULL,
  `codproducto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `costo` decimal(10,2) NOT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_recibo`
--

CREATE TABLE `detalle_recibo` (
  `id` int(11) NOT NULL,
  `noventa` bigint(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `saldo_anterior` decimal(10,2) NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `saldo_actual` decimal(10,2) NOT NULL,
  `usuario` int(11) NOT NULL,
  `caja` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_recibo_compra`
--

CREATE TABLE `detalle_recibo_compra` (
  `id` int(11) NOT NULL,
  `nocompra` bigint(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `saldo_anterior` decimal(10,2) NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `saldo_actual` decimal(10,2) NOT NULL,
  `usuario` int(11) NOT NULL,
  `caja` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp`
--

CREATE TABLE `detalle_temp` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `costo` decimal(10,2) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp_compra`
--

CREATE TABLE `detalle_temp_compra` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) CHARACTER SET latin1 NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `egresos`
--

CREATE TABLE `egresos` (
  `id` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `descripcion` text NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `usuario` int(11) NOT NULL,
  `caja` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entradas`
--

CREATE TABLE `entradas` (
  `correlativo` bigint(11) NOT NULL,
  `nocompra` bigint(11) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `usuario_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codproducto` int(20) NOT NULL,
  `codigo` varchar(20) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `proveedor` int(11) DEFAULT NULL,
  `costo` decimal(10,2) NOT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `existencia` int(11) NOT NULL,
  `foto` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `status` int(11) DEFAULT 1,
  `usuario_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codproducto`, `codigo`, `descripcion`, `proveedor`, `costo`, `precio`, `existencia`, `foto`, `date_add`, `status`, `usuario_id`) VALUES
(1325, 'DTSI20W5012', 'ACEITE 20W50 1.2 LTS', 1, '247.50', '280.00', 10, 'img_378a975b453639d824d34353a99bacbe.jpg', '2022-01-13 20:23:17', 1, 1),
(1326, 'DTSI20W502R', 'ACEITE 20W50 1 LTS', 1, '207.00', '235.00', 16, 'img_dc399ccd8b13e81ce0326821c3b42ae9.jpg', '2022-01-13 20:24:46', 1, 1),
(1327, 'DTSI20W503R', 'ACEITE 20W50 3R 1 LTS', 1, '193.50', '220.00', 7, 'img_08b718c6b302e9e9462e8a1a4449bc3c.jpg', '2022-01-13 20:25:52', 1, 1),
(1552, '7042292656', 'ACEITE RALLYE 140', 1, '155.00', '175.00', 9, 'img_ffd0cdeb3006a16c5073673d846a5a39.jpg', '2022-02-11 16:11:35', 1, 1),
(1553, 'MO402', 'ACEITE LION SAE 40', 1, '123.35', '155.00', 15, 'img_ea10e057fb6c6c85d052180b61762702.jpg', '2022-02-11 16:17:41', 1, 1),
(1554, '15C9BF', 'ACEITE CASTROL CRB MAX 15W-40', 1, '960.74', '1080.00', 0, 'img_ec5afd5d4f512d8b6ccdf3838852fc29.jpg', '2022-02-11 16:19:04', 1, 1),
(1555, '15D9C1', 'ACEITE CASTROL ACTEVO 4T 20W-50', 1, '237.46', '260.00', 8, 'img_b2adf96d67c8e73f4023fb450ae7f656.jpg', '2022-02-11 16:20:17', 1, 1),
(1556, 'MN7104-1', 'ACEITE MANNOL MNTS4 15W-40 ', 1, '124.71', '165.00', 15, 'img_7eab08200a0eac1198a184f47a5ed9eb.jpg', '2022-02-11 16:22:20', 1, 1),
(1557, '1030SNGF5BL', 'ACEITE ULTRA PLUS 10W-30', 1, '145.00', '170.00', 11, 'img_9005a00d6bfcebe68ac554e4d4a1e7e4.jpg', '2022-02-11 16:23:36', 1, 1),
(1558, '800-10-4', 'LIQUIDO DE FRENO FREE ROJO', 1, '53.69', '65.00', 11, 'img_2d3f21673b30a6dcbdd75e36865f23f1.jpg', '2022-02-11 16:24:59', 1, 1),
(1559, '800-10-3', 'LIQUIDO DE FRENO BLANCO', 1, '53.69', '65.00', 0, 'img_9bef084aa68a55d1b0476f89fab85543.jpg', '2022-02-11 16:25:43', 1, 1),
(1560, '15D2C4', 'Aceite Castrol Essential 4T 20W-50', 1, '189.29', '230.00', 5, 'img_cc0f017a87be402fae0d8837ef3926d0.jpg', '2022-02-11 16:26:49', 1, 1),
(2011, '1349', 'LUBRICANTE DE CADENA LIQUI MOLI', 1, '305.00', '360.00', 3, 'img_producto.png', '2022-07-08 18:54:38', 1, 1),
(2012, 'ACEITE HIDRAULICO RO', '1350', 1, '110.00', '135.00', 2, 'img_producto.png', '2022-07-08 18:55:49', 1, 1),
(2087, '1351', 'Aceite 2 tiempo', 1, '250.00', '300.00', 0, 'img_producto.png', '2022-09-15 15:04:09', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `codproveedor` int(11) NOT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `telefono` bigint(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `status` int(11) DEFAULT 1,
  `usuario_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`codproveedor`, `proveedor`, `contacto`, `telefono`, `direccion`, `date_add`, `status`, `usuario_id`) VALUES
(1, 'Mercado', 'Mercado', 99999999, 'Managua', '2021-09-21 15:52:42', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `idrol` int(11) NOT NULL,
  `rol` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`idrol`, `rol`) VALUES
(1, 'Administrador'),
(2, 'Supervisor'),
(3, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `usuario` varchar(15) DEFAULT NULL,
  `clave` varchar(100) DEFAULT NULL,
  `rol` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `correo`, `usuario`, `clave`, `rol`, `status`) VALUES
(1, 'Admin', 'admin@gmail.com', 'admin', '81dc9bdb52d04dc20036dbd8313ed055', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `noventa` bigint(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario` int(11) DEFAULT NULL,
  `caja` int(11) NOT NULL,
  `codcliente` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `totalventa` decimal(10,2) NOT NULL,
  `descuento` decimal(10,2) NOT NULL,
  `abono` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `caja`
--
ALTER TABLE `caja`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario` (`usuario`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`nocompra`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codproveedor` (`codproveedor`),
  ADD KEY `caja` (`caja`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detalleventa`
--
ALTER TABLE `detalleventa`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `noventa` (`noventa`);

--
-- Indices de la tabla `detalle_recibo`
--
ALTER TABLE `detalle_recibo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `noventa` (`noventa`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `caja` (`caja`);

--
-- Indices de la tabla `detalle_recibo_compra`
--
ALTER TABLE `detalle_recibo_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nocompra` (`nocompra`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `caja` (`caja`);

--
-- Indices de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `token_user` (`token_user`);

--
-- Indices de la tabla `detalle_temp_compra`
--
ALTER TABLE `detalle_temp_compra`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `token_user` (`token_user`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `egresos`
--
ALTER TABLE `egresos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `caja` (`caja`);

--
-- Indices de la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `nocompra` (`nocompra`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codproducto`),
  ADD KEY `proveedor` (`proveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`codproveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`idrol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `rol` (`rol`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`noventa`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codcliente` (`codcliente`),
  ADD KEY `caja` (`caja`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `caja`
--
ALTER TABLE `caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=161;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=74;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `nocompra` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=152;

--
-- AUTO_INCREMENT de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `detalleventa`
--
ALTER TABLE `detalleventa`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1543;

--
-- AUTO_INCREMENT de la tabla `detalle_recibo`
--
ALTER TABLE `detalle_recibo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=74;

--
-- AUTO_INCREMENT de la tabla `detalle_recibo_compra`
--
ALTER TABLE `detalle_recibo_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1958;

--
-- AUTO_INCREMENT de la tabla `detalle_temp_compra`
--
ALTER TABLE `detalle_temp_compra`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=160;

--
-- AUTO_INCREMENT de la tabla `egresos`
--
ALTER TABLE `egresos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=80;

--
-- AUTO_INCREMENT de la tabla `entradas`
--
ALTER TABLE `entradas`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=897;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `codproducto` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2088;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `codproveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `idrol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `noventa` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1188;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `caja`
--
ALTER TABLE `caja`
  ADD CONSTRAINT `caja_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`codproveedor`) REFERENCES `proveedor` (`codproveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `compras_ibfk_3` FOREIGN KEY (`caja`) REFERENCES `caja` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalleventa`
--
ALTER TABLE `detalleventa`
  ADD CONSTRAINT `detalleventa_ibfk_1` FOREIGN KEY (`noventa`) REFERENCES `venta` (`noventa`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalleventa_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_recibo`
--
ALTER TABLE `detalle_recibo`
  ADD CONSTRAINT `detalle_recibo_ibfk_1` FOREIGN KEY (`noventa`) REFERENCES `venta` (`noventa`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_recibo_ibfk_2` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_recibo_ibfk_3` FOREIGN KEY (`caja`) REFERENCES `caja` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_recibo_compra`
--
ALTER TABLE `detalle_recibo_compra`
  ADD CONSTRAINT `detalle_recibo_compra_ibfk_1` FOREIGN KEY (`nocompra`) REFERENCES `compras` (`nocompra`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_recibo_compra_ibfk_2` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_recibo_compra_ibfk_3` FOREIGN KEY (`caja`) REFERENCES `caja` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD CONSTRAINT `detalle_temp_ibfk_1` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `egresos`
--
ALTER TABLE `egresos`
  ADD CONSTRAINT `egresos_ibfk_1` FOREIGN KEY (`caja`) REFERENCES `caja` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD CONSTRAINT `entradas_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `entradas_ibfk_3` FOREIGN KEY (`nocompra`) REFERENCES `compras` (`nocompra`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `producto_ibfk_1` FOREIGN KEY (`proveedor`) REFERENCES `proveedor` (`codproveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `producto_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD CONSTRAINT `proveedor_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`rol`) REFERENCES `rol` (`idrol`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `venta`
--
ALTER TABLE `venta`
  ADD CONSTRAINT `venta_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `venta_ibfk_2` FOREIGN KEY (`codcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `venta_ibfk_3` FOREIGN KEY (`caja`) REFERENCES `caja` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
