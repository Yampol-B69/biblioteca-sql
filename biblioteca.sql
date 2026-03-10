-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 10-03-2026 a las 03:25:29
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bibliotec`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_socio` (IN `id_socio` INT, IN `nueva_direccion` VARCHAR(255), IN `nuevo_telefono` VARCHAR(10))   BEGIN

UPDATE tbl_socio
SET 
SOC_DIRECCION = nueva_direccion,
SOC_TELEFONO = nuevo_telefono
WHERE SOC_NUMERO = id_socio;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_libro_nombre` (IN `p_nombre` VARCHAR(255))   BEGIN 
SELECT * 
FROM tbl_libro 
WHERE LIB_TITULO LIKE 
CONCAT('%', p_nombre, '%'); 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_libro` (IN `p_isbn` BIGINT)   BEGIN
DECLARE existe INT;
SELECT COUNT(*) INTO existe
FROM tbl_prestamo
WHERE LIB_COPIAISBN = p_isbn;
IF existe = 0 THEN
DELETE FROM tbl_libro
WHERE LIB_ISBN = p_isbn;
ELSE
SELECT 'No se puede eliminar, tiene
prestamos' AS mensaje;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_libro_seguro` (IN `p_isbn` BIGINT, OUT `p_mensaje` VARCHAR(255))   BEGIN
    DECLARE prestamos_activos INT;
    DECLARE libro_existe INT;
    
    -- Verificar si el libro existe
    SELECT COUNT(*) INTO libro_existe
    FROM tbl_libro
    WHERE LIB_ISBN = p_isbn;
    
    IF libro_existe = 0 THEN
        SET p_mensaje = 'El libro no existe';
    ELSE
        -- Verificar si tiene préstamos
        SELECT COUNT(*) INTO prestamos_activos
        FROM tbl_prestamo
        WHERE LIB_COPIAISBN = p_isbn;
        
        IF prestamos_activos > 0 THEN
            SET p_mensaje = CONCAT('No se puede eliminar: el libro tiene ', prestamos_activos, ' préstamo(s) activo(s)');
        ELSE
            -- Eliminar el libro (el trigger de auditoría registrará automáticamente)
            DELETE FROM tbl_libro WHERE LIB_ISBN = p_isbn;
            SET p_mensaje = 'Libro eliminado exitosamente';
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertar_socio` (IN `p_numero` INT, IN `p_nombre` VARCHAR(45), IN `p_apellido` VARCHAR(45), IN `p_direccion` VARCHAR(255), IN `p_telefono` VARCHAR(10))   begin  
insert into tbl_socio values (p_numero, p_nombre, p_apellido, p_direccion, 
p_telefono); 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_libro` (IN `p_isbn` BIGINT, IN `p_titulo` VARCHAR(255), IN `p_genero` VARCHAR(20), IN `p_paginas` INT, IN `p_dias` INT)   BEGIN

INSERT INTO tbl_libro
VALUES (p_isbn,p_titulo,p_genero,p_paginas,p_dias);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_libros_en_prestamo` ()   BEGIN 
    SELECT 
    l.LIB_TITULO, 
    S.SOC_NOMBRE, 
    P.PRES_FECHAPRESTAMO, 
    
P.PRES_FECHADEVOLUCION 
    FROM tbl_prestamo P      INNER JOIN tbl_libro l     on p.LIB_COPIAISBN = l.LIB_ISBN 
    INNER JOIN tbl_socio s      on p.SOC_COPIANUMERO = s.SOC_NUMERO; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listaAutores` ()   BEGIN
SELECT * FROM tbl_autor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_socios_con_prestamos` ()   BEGIN
SELECT
S.SOC_NUMERO,
S.SOC_NOMBRE,
P.PRES_ID,
P.PRES_FECHAPRESTAMO,
P.PRES_FECHADEVOLUCION
FROM tbl_socio S
LEFT JOIN tbl_prestamo P
ON S.SOC_NUMERO =
P.SOC_COPIANUMERO;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_socios_prestamos` ()   BEGIN
SELECT 
    s.SOC_NUMERO,
    s.SOC_NOMBRE,
    s.SOC_APELLIDO,
    p.PRES_ID,
    p.PRES_FECHAPRESTAMO,
    p.PRES_FECHADEVOLUCION
FROM tbl_socio s
LEFT JOIN tbl_prestamo p 
ON s.SOC_NUMERO = p.SOC_COPIANUMERO;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tipoAutor` (IN `p_codigo` INT)   BEGIN

DECLARE tipo VARCHAR(50);

IF p_codigo < 200 THEN
SET tipo = 'Autor clásico';
ELSE
SET tipo = 'Autor moderno';
END IF;

SELECT tipo AS TipoAutor;

END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_dias_prestamo` (`p_isbn` BIGINT) RETURNS INT(11) DETERMINISTIC BEGIN 
    DECLARE dias INT; 
 
    SELECT DATEDIFF( 
        IFNULL(PRES_FECHADEVOLUCION, 
CURDATE()), 
        PRES_FECHAPRESTAMO 
    ) 
    INTO dias 
    FROM tbl_prestamo 
    WHERE LIB_COPIAISBN = p_isbn 
    LIMIT 1; 
 
    RETURN dias; 
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_socios` () RETURNS INT(11) DETERMINISTIC BEGIN 
    DECLARE total INT; 
 
    SELECT COUNT(*) INTO total 
    FROM tbl_socio; 
 
    RETURN total; 
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria_libros`
--

CREATE TABLE `auditoria_libros` (
  `id_auditoria` int(11) NOT NULL,
  `accion` varchar(20) DEFAULT NULL,
  `isbn` bigint(20) DEFAULT NULL,
  `titulo` varchar(255) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `audi_autor`
--

CREATE TABLE `audi_autor` (
  `id_audi_autor` int(11) NOT NULL,
  `aut_codigo_audi` int(11) DEFAULT NULL,
  `aut_apellido_anterior` varchar(45) DEFAULT NULL,
  `aut_nacimiento_anterior` date DEFAULT NULL,
  `aut_muerte_anterior` date DEFAULT NULL,
  `aut_apellido_nuevo` varchar(45) DEFAULT NULL,
  `aut_nacimiento_nuevo` date DEFAULT NULL,
  `aut_muerte_nuevo` date DEFAULT NULL,
  `audi_fecha_modificacion` datetime DEFAULT NULL,
  `audi_usuario` varchar(50) DEFAULT NULL,
  `audi_accion` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `audi_autor`
--

INSERT INTO `audi_autor` (`id_audi_autor`, `aut_codigo_audi`, `aut_apellido_anterior`, `aut_nacimiento_anterior`, `aut_muerte_anterior`, `aut_apellido_nuevo`, `aut_nacimiento_nuevo`, `aut_muerte_nuevo`, `audi_fecha_modificacion`, `audi_usuario`, `audi_accion`) VALUES
(1, 456, 'García ', '1978-09-27', '2021-12-09', 'García Actualizado', '1978-09-27', '2021-12-09', '2026-03-09 20:53:16', 'root@localhost', 'UPDATE'),
(4, 98, 'Smith ', '1974-12-21', '2018-07-21', NULL, NULL, NULL, '2026-03-09 21:00:40', 'root@localhost', 'DELETE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `audi_libro`
--

CREATE TABLE `audi_libro` (
  `id_audi_libro` int(11) NOT NULL,
  `lib_isbn_audi` bigint(20) DEFAULT NULL,
  `lib_titulo_anterior` varchar(255) DEFAULT NULL,
  `lib_genero_anterior` varchar(20) DEFAULT NULL,
  `lib_numeropaginas_anterior` int(11) DEFAULT NULL,
  `lib_diasprestamo_anterior` tinyint(4) DEFAULT NULL,
  `lib_titulo_nuevo` varchar(255) DEFAULT NULL,
  `lib_genero_nuevo` varchar(20) DEFAULT NULL,
  `lib_numeropaginas_nuevo` int(11) DEFAULT NULL,
  `lib_diasprestamo_nuevo` tinyint(4) DEFAULT NULL,
  `audi_fecha_modificacion` datetime DEFAULT NULL,
  `audi_usuario` varchar(50) DEFAULT NULL,
  `audi_accion` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `audi_libro`
--

INSERT INTO `audi_libro` (`id_audi_libro`, `lib_isbn_audi`, `lib_titulo_anterior`, `lib_genero_anterior`, `lib_numeropaginas_anterior`, `lib_diasprestamo_anterior`, `lib_titulo_nuevo`, `lib_genero_nuevo`, `lib_numeropaginas_nuevo`, `lib_diasprestamo_nuevo`, `audi_fecha_modificacion`, `audi_usuario`, `audi_accion`) VALUES
(1, 1234567890123, 'Libro de Prueba', 'Novela', 300, 7, 'Libro de Prueba Modificado', 'Aventura', 350, 7, '2026-03-09 20:14:34', 'root@localhost', 'UPDATE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `audi_socio`
--

CREATE TABLE `audi_socio` (
  `id_audi` int(10) NOT NULL,
  `socNumero_audi` int(11) DEFAULT NULL,
  `socNombre_anterior` varchar(45) DEFAULT NULL,
  `socApellido_anterior` varchar(45) DEFAULT NULL,
  `socDireccion_anterior` varchar(255) DEFAULT NULL,
  `socTelefono_anterior` varchar(10) DEFAULT NULL,
  `socNombre_nuevo` varchar(45) DEFAULT NULL,
  `socApellido_nuevo` varchar(45) DEFAULT NULL,
  `socDireccion_nuevo` varchar(255) DEFAULT NULL,
  `socTelefono_nuevo` varchar(10) DEFAULT NULL,
  `audi_fechaModificacion` datetime DEFAULT NULL,
  `audi_usuario` varchar(10) DEFAULT NULL,
  `audi_accion` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `audi_socio`
--

INSERT INTO `audi_socio` (`id_audi`, `socNumero_audi`, `socNombre_anterior`, `socApellido_anterior`, `socDireccion_anterior`, `socTelefono_anterior`, `socNombre_nuevo`, `socApellido_nuevo`, `socDireccion_nuevo`, `socTelefono_nuevo`, `audi_fechaModificacion`, `audi_usuario`, `audi_accion`) VALUES
(1, 20, NULL, NULL, NULL, NULL, 'Pedro', 'Lopez', 'Calle 50', '3001234567', '2026-03-09 16:22:14', 'root@local', 'INSERT'),
(2, 20, 'Pedro', 'Lopez', 'Calle 50', '3001234567', 'Pedro', 'Lopez', 'Calle 50', '3142135461', '2026-03-09 16:28:54', 'root@local', 'Actualización'),
(3, 20, 'Pedro', 'Lopez', 'Calle 50', '3001234567', 'Pedro', 'Lopez', 'Calle 50', '3142135461', '2026-03-09 16:28:54', 'root@local', 'UPDATE'),
(4, 20, 'Pedro', 'Lopez', 'Calle 50', '3142135461', NULL, NULL, NULL, NULL, '2026-03-09 16:31:02', 'root@local', 'Registro eliminado'),
(5, 1, 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '9123456780', 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '3209999999', '2026-03-09 17:24:47', 'root@local', 'Actualización'),
(6, 1, 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '9123456780', 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '3209999999', '2026-03-09 17:24:47', 'root@local', 'UPDATE'),
(7, 1, 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '9123456780', 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '3209999999', '2026-03-09 17:24:47', 'root@local', 'UPDATE'),
(10, 99, NULL, NULL, NULL, NULL, 'Juan', 'Prueba', '', '', '2026-03-09 18:54:55', 'root@local', 'INSERT'),
(11, 99, 'Juan', 'Prueba', '', '', 'Juan', 'Prueba', 'calle 10', '32135872', '2026-03-09 18:56:02', 'root@local', 'Actualización'),
(12, 99, 'Juan', 'Prueba', '', '', 'Juan', 'Prueba', 'calle 10', '32135872', '2026-03-09 18:56:02', 'root@local', 'UPDATE'),
(13, 99, 'Juan', 'Prueba', '', '', 'Juan', 'Prueba', 'calle 10', '32135872', '2026-03-09 18:56:02', 'root@local', 'UPDATE'),
(14, 99, 'Juan', 'Prueba', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-09 18:56:30', 'root@local', 'DELETE'),
(15, 99, 'Juan', 'Prueba', 'calle 10', '32135872', NULL, NULL, NULL, NULL, '2026-03-09 18:56:30', 'root@local', 'Registro eliminado'),
(16, 99, NULL, NULL, NULL, NULL, 'Juan', 'Prueba', 'calle 40', '303456789', '2026-03-09 19:09:21', 'root@local', 'INSERT'),
(17, 99, 'Juan', 'Prueba', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-09 19:11:30', 'root@local', 'DELETE'),
(18, 99, 'Juan', 'Prueba', 'calle 40', '303456789', NULL, NULL, NULL, NULL, '2026-03-09 19:11:30', 'root@local', 'Registro eliminado'),
(19, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-09 19:17:16', 'root@local', 'INSERT LIBRO'),
(20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-09 20:14:34', 'root@local', 'INSERT LIBRO'),
(21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-09 20:14:34', 'root@local', 'UPDATE LIBRO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_autor`
--

CREATE TABLE `tbl_autor` (
  `AUT_CODIGO` int(11) NOT NULL,
  `AUT_APELLIDO` varchar(45) NOT NULL,
  `AUT_NACIMIENTO` date NOT NULL,
  `AUT_MUERTE` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_autor`
--

INSERT INTO `tbl_autor` (`AUT_CODIGO`, `AUT_APELLIDO`, `AUT_NACIMIENTO`, `AUT_MUERTE`) VALUES
(0, 'aut_apellido ', '0000-00-00', '0000-00-00'),
(123, 'Taylor ', '1980-04-15', '0000-00-00'),
(234, 'Medina ', '1977-06-21', '2005-09-12'),
(345, 'Wilson ', '1975-08-29', '0000-00-00'),
(432, 'Miller ', '1981-10-26', '0000-00-00'),
(456, 'García Actualizado', '1978-09-27', '2021-12-09'),
(567, 'Davis ', '1983-03-04', '2010-03-28'),
(678, 'Silva ', '1986-02-02', '0000-00-00'),
(765, 'López ', '1976-07-08', '2005-05-20'),
(789, 'Rodríguez ', '1985-12-10', '0000-00-00'),
(890, 'Brown ', '1982-11-17', '0000-00-00'),
(901, 'Soto ', '1979-05-13', '2015-11-05');

--
-- Disparadores `tbl_autor`
--
DELIMITER $$
CREATE TRIGGER `trg_autor_delete_auditoria` BEFORE DELETE ON `tbl_autor` FOR EACH ROW BEGIN
    INSERT INTO audi_autor(
        aut_codigo_audi,
        aut_apellido_anterior,
        aut_nacimiento_anterior,
        aut_muerte_anterior,
        audi_fecha_modificacion,
        audi_usuario,
        audi_accion
    )
    VALUES(
        OLD.AUT_CODIGO,
        OLD.AUT_APELLIDO,
        OLD.AUT_NACIMIENTO,
        OLD.AUT_MUERTE,
        NOW(),
        USER(),
        'DELETE'
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_autor_update_auditoria` AFTER UPDATE ON `tbl_autor` FOR EACH ROW BEGIN
    INSERT INTO audi_autor(
        aut_codigo_audi,
        aut_apellido_anterior,
        aut_nacimiento_anterior,
        aut_muerte_anterior,
        aut_apellido_nuevo,
        aut_nacimiento_nuevo,
        aut_muerte_nuevo,
        audi_fecha_modificacion,
        audi_usuario,
        audi_accion
    )
    VALUES(
        OLD.AUT_CODIGO,
        OLD.AUT_APELLIDO,
        OLD.AUT_NACIMIENTO,
        OLD.AUT_MUERTE,
        NEW.AUT_APELLIDO,
        NEW.AUT_NACIMIENTO,
        NEW.AUT_MUERTE,
        NOW(),
        USER(),
        'UPDATE'
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_libro`
--

CREATE TABLE `tbl_libro` (
  `LIB_ISBN` bigint(20) NOT NULL,
  `LIB_TITULO` varchar(255) NOT NULL,
  `LIB_GENERO` varchar(20) NOT NULL,
  `LIB_NUMEROPAGINAS` int(11) NOT NULL,
  `LIB_DIASPRESTAMO` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_libro`
--

INSERT INTO `tbl_libro` (`LIB_ISBN`, `LIB_TITULO`, `LIB_GENERO`, `LIB_NUMEROPAGINAS`, `LIB_DIASPRESTAMO`) VALUES
(0, 'lib_titulo ', 'lib_genero ', 0, 0),
(999999, 'Libro prueba', 'Novela', 200, 10),
(1234567890, 'El Sueño de los Susurros ', 'novela ', 275, 7),
(1357924680, 'El Jardín de las Mariposas Perdidas ', 'novela ', 536, 7),
(2468135790, 'La Melodía de la Oscuridad ', 'romance ', 189, 7),
(2718281828, 'El Bosque de los Suspiros ', 'novela ', 387, 2),
(3141592653, 'El Secreto de las Estrellas Olvidadas ', 'Misterio ', 203, 7),
(5555555555, 'La Última Llave del Destino ', 'cuento ', 503, 7),
(7777777777, 'El Misterio de la Luna Plateada ', 'Misterio ', 422, 7),
(8642097531, 'El Reloj de Arena Infinito ', 'novela ', 321, 7),
(8888888888, 'La Ciudad de los Susurros ', 'Misterio ', 274, 1),
(9517530862, 'Las Crónicas del Eco Silencioso ', 'fantasía ', 448, 7),
(9876543210, 'El Laberinto de los Recuerdos ', 'cuento ', 412, 7),
(9999999999, 'El Enigma de los Espejos Rotos ', 'romance ', 156, 7);

--
-- Disparadores `tbl_libro`
--
DELIMITER $$
CREATE TRIGGER `trg_insert_libro` AFTER INSERT ON `tbl_libro` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario
)

VALUES(
'INSERT LIBRO',
NOW(),
USER()
);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_libro_delete_auditoria` BEFORE DELETE ON `tbl_libro` FOR EACH ROW BEGIN
    DECLARE prestamos_activos INT;
    
    SELECT COUNT(*) INTO prestamos_activos
    FROM tbl_prestamo
    WHERE LIB_COPIAISBN = OLD.LIB_ISBN;
    
   
    IF prestamos_activos > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se puede eliminar el libro porque tiene préstamos asociados';
    ELSE
       
        INSERT INTO audi_libro(
            lib_isbn_audi,
            lib_titulo_anterior,
            lib_genero_anterior,
            lib_numeropaginas_anterior,
            lib_diasprestamo_anterior,
            audi_fecha_modificacion,
            audi_usuario,
            audi_accion
        )
        VALUES(
            OLD.LIB_ISBN,
            OLD.LIB_TITULO,
            OLD.LIB_GENERO,
            OLD.LIB_NUMEROPAGINAS,
            OLD.LIB_DIASPRESTAMO,
            NOW(),
            USER(),
            'DELETE'
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_libro_update` AFTER UPDATE ON `tbl_libro` FOR EACH ROW BEGIN
    INSERT INTO audi_libro(
        lib_isbn_audi,
        lib_titulo_anterior,
        lib_genero_anterior,
        lib_numeropaginas_anterior,
        lib_diasprestamo_anterior,
        lib_titulo_nuevo,
        lib_genero_nuevo,
        lib_numeropaginas_nuevo,
        lib_diasprestamo_nuevo,
        audi_fecha_modificacion,
        audi_usuario,
        audi_accion
    )
    VALUES(
        NEW.LIB_ISBN,
        OLD.LIB_TITULO,
        OLD.LIB_GENERO,
        OLD.LIB_NUMEROPAGINAS,
        OLD.LIB_DIASPRESTAMO,
        NEW.LIB_TITULO,
        NEW.LIB_GENERO,
        NEW.LIB_NUMEROPAGINAS,
        NEW.LIB_DIASPRESTAMO,
        NOW(),
        USER(),
        'UPDATE'
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_libro` AFTER UPDATE ON `tbl_libro` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario
)

VALUES(
'UPDATE LIBRO',
NOW(),
USER()
);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_prestamo`
--

CREATE TABLE `tbl_prestamo` (
  `PRES_ID` varchar(20) NOT NULL,
  `PRES_FECHAPRESTAMO` date NOT NULL,
  `PRES_FECHADEVOLUCION` date NOT NULL,
  `SOC_COPIANUMERO` int(11) DEFAULT NULL,
  `LIB_COPIAISBN` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_socio`
--

CREATE TABLE `tbl_socio` (
  `SOC_NUMERO` int(11) NOT NULL,
  `SOC_NOMBRE` varchar(45) NOT NULL,
  `SOC_APELLIDO` varchar(45) NOT NULL,
  `SOC_DIRECCION` varchar(255) NOT NULL,
  `SOC_TELEFONO` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_socio`
--

INSERT INTO `tbl_socio` (`SOC_NUMERO`, `SOC_NOMBRE`, `SOC_APELLIDO`, `SOC_DIRECCION`, `SOC_TELEFONO`) VALUES
(0, 'soc_nombre ', 'soc_apellido ', 'soc_direccion ', 'soc_telefo'),
(1, 'Ana ', 'Ruiz ', 'Calle Primavera 123, Ciudad Jardín, Barcelona ', '3209999999'),
(2, 'Andrés Felipe ', 'Galindo Luna ', 'Avenida del Sol 456, Pueblo Nuevo, Madrid ', '2123456789'),
(3, 'Juan ', 'González ', 'Calle Principal 789, Villa Flores, Valencia ', '2012345678'),
(4, 'María ', 'Rodríguez ', 'Carrera del Río 321, El Pueblo, Sevilla ', '3012345678'),
(5, 'Pedro ', 'Martínez ', 'Calle del Bosque 654, Los Pinos, Málaga ', '1234567812'),
(6, 'Ana ', 'López ', 'Avenida Central 987, Villa Hermosa, Bilbao ', '6123456781'),
(7, 'Carlos ', 'Sánchez ', 'Calle de la Luna 234, El Prado, Alicante ', '1123456781'),
(8, 'Laura ', 'Ramírez ', 'Carrera del Mar 567, Playa Azul, Palma de Mallorca ', '1312345678'),
(9, 'Luis ', 'Hernández ', 'Avenida de la Montaña 890, Monte Verde, Granada ', '6101234567'),
(10, 'Andrea ', 'García ', 'Calle del Sol 432, La Colina, Zaragoza ', '1112345678'),
(11, 'Alejandro ', 'Torres ', 'Carrera del Oeste 765, Ciudad Nueva, Murcia ', '4951234567'),
(12, 'Sofia ', 'Morales ', 'Avenida del Mar 098, Costa Brava, Gijón ', '5512345678'),
(13, 'Yampol', 'Bonilla', 'Calle 48', '3041034401');

--
-- Disparadores `tbl_socio`
--
DELIMITER $$
CREATE TRIGGER `socios_after_delete` AFTER DELETE ON `tbl_socio` FOR EACH ROW INSERT INTO audi_socio(
socNumero_audi,
socNombre_anterior,
socApellido_anterior,
socDireccion_anterior,
socTelefono_anterior,
audi_fechaModificacion,
audi_usuario,
audi_accion)
VALUES(
old.soc_numero,
old.soc_nombre,
old.soc_apellido,
old.soc_direccion,
old.soc_telefono,
NOW(),
CURRENT_USER(),
'Registro eliminado')
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `socios_before_update` BEFORE UPDATE ON `tbl_socio` FOR EACH ROW INSERT INTO audi_socio(
socNumero_audi,
socNombre_anterior,
socApellido_anterior,
socDireccion_anterior,
socTelefono_anterior,
socNombre_nuevo,
socApellido_nuevo,
socDireccion_nuevo,
socTelefono_nuevo,
audi_fechaModificacion,
audi_usuario,
audi_accion)
VALUES(
new.soc_numero,
old.soc_nombre,
old.soc_apellido,
old.soc_direccion,
old.soc_telefono,
new.soc_nombre,
new.soc_apellido,
new.soc_direccion,
new.soc_telefono,
NOW(),
CURRENT_USER(),
'Actualización')
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_delete_socio` BEFORE DELETE ON `tbl_socio` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario,
socNumero_audi,
socNombre_anterior,
socApellido_anterior
)

VALUES(
'DELETE',
NOW(),
USER(),
OLD.SOC_NUMERO,
OLD.SOC_NOMBRE,
OLD.SOC_APELLIDO
);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_socio_insert` AFTER INSERT ON `tbl_socio` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario,
socNumero_audi,
socNombre_nuevo,
socApellido_nuevo,
socDireccion_nuevo,
socTelefono_nuevo
)

VALUES(
'INSERT',
NOW(),
USER(),
NEW.SOC_NUMERO,
NEW.SOC_NOMBRE,
NEW.SOC_APELLIDO,
NEW.SOC_DIRECCION,
NEW.SOC_TELEFONO
);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_socio_update` AFTER UPDATE ON `tbl_socio` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario,
socNumero_audi,

socNombre_anterior,
socNombre_nuevo,

socApellido_anterior,
socApellido_nuevo,

socDireccion_anterior,
socDireccion_nuevo,

socTelefono_anterior,
socTelefono_nuevo
)

VALUES(
'UPDATE',
NOW(),
USER(),
NEW.SOC_NUMERO,

OLD.SOC_NOMBRE,
NEW.SOC_NOMBRE,

OLD.SOC_APELLIDO,
NEW.SOC_APELLIDO,

OLD.SOC_DIRECCION,
NEW.SOC_DIRECCION,

OLD.SOC_TELEFONO,
NEW.SOC_TELEFONO
);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_socio` AFTER UPDATE ON `tbl_socio` FOR EACH ROW BEGIN

INSERT INTO audi_socio(
audi_accion,
audi_fechaModificacion,
audi_usuario,
socNumero_audi,
socNombre_anterior,
socNombre_nuevo,
socApellido_anterior,
socApellido_nuevo,
socDireccion_anterior,
socDireccion_nuevo,
socTelefono_anterior,
socTelefono_nuevo
)

VALUES(
'UPDATE',
NOW(),
USER(),
OLD.SOC_NUMERO,
OLD.SOC_NOMBRE,
NEW.SOC_NOMBRE,
OLD.SOC_APELLIDO,
NEW.SOC_APELLIDO,
OLD.SOC_DIRECCION,
NEW.SOC_DIRECCION,
OLD.SOC_TELEFONO,
NEW.SOC_TELEFONO
);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_tipoautores`
--

CREATE TABLE `tbl_tipoautores` (
  `COPIAISBN` bigint(20) NOT NULL,
  `COPIAAUTOR` int(11) DEFAULT NULL,
  `TIPOAUTOR` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_tipoautores`
--

INSERT INTO `tbl_tipoautores` (`COPIAISBN`, `COPIAAUTOR`, `TIPOAUTOR`) VALUES
(0, 0, 'tipoAutor'),
(1357924680, 123, 'Traductor'),
(1234567890, 123, 'Autor'),
(1234567890, 456, 'Coautor'),
(2718281828, 789, 'Traductor'),
(8888888888, 234, 'Autor'),
(2468135790, 234, 'Autor'),
(9876543210, 567, 'Autor'),
(1234567890, 890, 'Autor'),
(8642097531, 345, 'Autor'),
(8888888888, 345, 'Coautor'),
(5555555555, 678, 'Autor'),
(3141592653, 901, 'Autor'),
(9517530862, 432, 'Autor'),
(7777777777, 765, 'Autor');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_libros_prestados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_libros_prestados` (
`LIB_TITULO` varchar(255)
,`SOC_NOMBRE` varchar(45)
,`PRES_FECHAPRESTAMO` date
,`PRES_FECHADEVOLUCION` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_socios_prestamo`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_socios_prestamo` (
`SOC_NOMBRE` varchar(45)
,`SOC_APELLIDO` varchar(45)
,`PRES_ID` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_libros_prestados`
--
DROP TABLE IF EXISTS `vista_libros_prestados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_libros_prestados`  AS SELECT `l`.`LIB_TITULO` AS `LIB_TITULO`, `s`.`SOC_NOMBRE` AS `SOC_NOMBRE`, `p`.`PRES_FECHAPRESTAMO` AS `PRES_FECHAPRESTAMO`, `p`.`PRES_FECHADEVOLUCION` AS `PRES_FECHADEVOLUCION` FROM ((`tbl_prestamo` `p` join `tbl_libro` `l` on(`p`.`LIB_COPIAISBN` = `l`.`LIB_ISBN`)) join `tbl_socio` `s` on(`p`.`SOC_COPIANUMERO` = `s`.`SOC_NUMERO`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_socios_prestamo`
--
DROP TABLE IF EXISTS `vista_socios_prestamo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_socios_prestamo`  AS SELECT `s`.`SOC_NOMBRE` AS `SOC_NOMBRE`, `s`.`SOC_APELLIDO` AS `SOC_APELLIDO`, `p`.`PRES_ID` AS `PRES_ID` FROM (`tbl_socio` `s` left join `tbl_prestamo` `p` on(`s`.`SOC_NUMERO` = `p`.`SOC_COPIANUMERO`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoria_libros`
--
ALTER TABLE `auditoria_libros`
  ADD PRIMARY KEY (`id_auditoria`);

--
-- Indices de la tabla `audi_autor`
--
ALTER TABLE `audi_autor`
  ADD PRIMARY KEY (`id_audi_autor`);

--
-- Indices de la tabla `audi_libro`
--
ALTER TABLE `audi_libro`
  ADD PRIMARY KEY (`id_audi_libro`);

--
-- Indices de la tabla `audi_socio`
--
ALTER TABLE `audi_socio`
  ADD PRIMARY KEY (`id_audi`);

--
-- Indices de la tabla `tbl_autor`
--
ALTER TABLE `tbl_autor`
  ADD PRIMARY KEY (`AUT_CODIGO`);

--
-- Indices de la tabla `tbl_libro`
--
ALTER TABLE `tbl_libro`
  ADD PRIMARY KEY (`LIB_ISBN`),
  ADD KEY `idx_lib_titulo` (`LIB_TITULO`);

--
-- Indices de la tabla `tbl_prestamo`
--
ALTER TABLE `tbl_prestamo`
  ADD PRIMARY KEY (`PRES_ID`),
  ADD KEY `SOC_COPIANUMERO` (`SOC_COPIANUMERO`),
  ADD KEY `LIB_COPIAISBN` (`LIB_COPIAISBN`);

--
-- Indices de la tabla `tbl_socio`
--
ALTER TABLE `tbl_socio`
  ADD PRIMARY KEY (`SOC_NUMERO`);

--
-- Indices de la tabla `tbl_tipoautores`
--
ALTER TABLE `tbl_tipoautores`
  ADD KEY `COPIAISBN` (`COPIAISBN`),
  ADD KEY `COPIAAUTOR` (`COPIAAUTOR`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria_libros`
--
ALTER TABLE `auditoria_libros`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `audi_autor`
--
ALTER TABLE `audi_autor`
  MODIFY `id_audi_autor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `audi_libro`
--
ALTER TABLE `audi_libro`
  MODIFY `id_audi_libro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `audi_socio`
--
ALTER TABLE `audi_socio`
  MODIFY `id_audi` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `tbl_prestamo`
--
ALTER TABLE `tbl_prestamo`
  ADD CONSTRAINT `tbl_prestamo_ibfk_1` FOREIGN KEY (`SOC_COPIANUMERO`) REFERENCES `tbl_socio` (`SOC_NUMERO`),
  ADD CONSTRAINT `tbl_prestamo_ibfk_2` FOREIGN KEY (`LIB_COPIAISBN`) REFERENCES `tbl_libro` (`LIB_ISBN`);

--
-- Filtros para la tabla `tbl_tipoautores`
--
ALTER TABLE `tbl_tipoautores`
  ADD CONSTRAINT `tbl_tipoautores_ibfk_1` FOREIGN KEY (`COPIAISBN`) REFERENCES `tbl_libro` (`LIB_ISBN`),
  ADD CONSTRAINT `tbl_tipoautores_ibfk_2` FOREIGN KEY (`COPIAAUTOR`) REFERENCES `tbl_autor` (`AUT_CODIGO`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `eliminar_prestamos` ON SCHEDULE EVERY 1 DAY STARTS '2026-03-09 21:04:32' ENDS '2027-03-09 21:04:32' ON COMPLETION NOT PRESERVE ENABLE DO DELETE FROM tbl_prestamo
WHERE PRES_FECHADEVOLUCION < CURDATE()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
