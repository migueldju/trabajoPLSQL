DROP TABLE detalle_pedido CASCADE CONSTRAINTS;
DROP TABLE pedidos CASCADE CONSTRAINTS;
DROP TABLE platos CASCADE CONSTRAINTS;
DROP TABLE personal_servicio CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pedidos;


-- Creación de tablas y secuencias



create sequence seq_pedidos;

CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20)
);

CREATE TABLE personal_servicio (
    id_personal INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
);

CREATE TABLE platos (
    id_plato INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    disponible INTEGER DEFAULT 1 CHECK (DISPONIBLE in (0,1))
);

CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_personal INTEGER REFERENCES personal_servicio(id_personal),
    fecha_pedido DATE DEFAULT SYSDATE,
    total DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE detalle_pedido (
    id_pedido INTEGER REFERENCES pedidos(id_pedido),
    id_plato INTEGER REFERENCES platos(id_plato),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (id_pedido, id_plato)
);


	
-- Procedimiento a implementar para realizar la reserva
CREATE OR REPLACE PROCEDURE registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) IS
  v_id_pedido INTEGER;
  
  CURSOR pedidosPersonal IS
  SELECT pedidos_activos
  FROM personal_servicio
  WHERE id_personal = arg_id_personal;
  
  nPedidosPersonal INTEGER;
  
  CURSOR disponibilidadPrimero IS
  SELECT disponible
  FROM platos
  WHERE id_plato = arg_id_primer_plato;
  
  CURSOR disponibilidadSegundo IS
  SELECT disponible
  FROM platos
  WHERE id_plato = arg_id_segundo_plato;
  
  primeroDisponible NUMBER;
  segundoDisponible NUMBER;
  
BEGIN
  IF arg_id_primer_plato IS NULL AND arg_id_segundo_plato IS NULL THEN
    RAISE_APPLICATION_ERROR(-20002, 'El pedido debe contener al menos un plato.');
  END IF;
  OPEN pedidosPersonal;
  FETCH pedidosPersonal INTO nPedidosPersonal;
  IF nPedidosPersonal >= 5 THEN
    CLOSE pedidosPersonal;
    RAISE_APPLICATION_ERROR(-20003, 'El personal de servicio tiene demasiados pedidos');
  END IF;
  CLOSE pedidosPersonal;
  IF arg_id_primer_plato IS NOT NULL THEN    
    OPEN disponibilidadPrimero;
    FETCH disponibilidadPrimero INTO primeroDisponible;
    IF disponibilidadPrimero%NOTFOUND THEN
      CLOSE disponibilidadPrimero;
      RAISE_APPLICATION_ERROR(-20004, 'El primer plato seleccionado no existe.');
    END IF;
    IF primeroDisponible = 0 THEN -- 0 means FALSE
      CLOSE disponibilidadPrimero;
      RAISE_APPLICATION_ERROR(-20001, 'Uno de los platos seleccionados no está disponible.');
    END IF;
    CLOSE disponibilidadPrimero;
  END IF;
  IF arg_id_segundo_plato IS NOT NULL THEN 
    OPEN disponibilidadSegundo;
    FETCH disponibilidadSegundo INTO segundoDisponible;
    IF disponibilidadSegundo%NOTFOUND THEN
      CLOSE disponibilidadSegundo;
      RAISE_APPLICATION_ERROR(-20004, 'El segundo plato seleccionado no existe.');
    END IF;
<<<<<<< HEAD
    IF segundoDisponible = 0 THEN -- 0 means FALSE
      CLOSE disponibilidadSegundo;
      RAISE_APPLICATION_ERROR(-20001, 'Uno de los platos seleccionados no está disponible.');
    END IF;
    CLOSE disponibilidadSegundo;
  END IF;
  v_id_pedido := seq_pedidos.nextval;
  INSERT INTO pedidos(id_pedido, id_cliente, id_personal, fecha_pedido, total)
  VALUES(v_id_pedido, arg_id_cliente, arg_id_personal, SYSDATE, 0);
  IF arg_id_primer_plato IS NOT NULL THEN
    INSERT INTO detalle_pedido(id_pedido, id_plato, cantidad)
    VALUES(v_id_pedido, arg_id_primer_plato, 1);  
  END IF;
  IF arg_id_segundo_plato IS NOT NULL THEN
    INSERT INTO detalle_pedido(id_pedido, id_plato, cantidad)
    VALUES(v_id_pedido, arg_id_segundo_plato, 1);  
  END IF;
  UPDATE personal_servicio
  SET pedidos_activos = pedidos_activos + 1
  WHERE id_personal = arg_id_personal;
  COMMIT;
END;
=======

    v_id_pedido := seq_pedidos.nextval;
    INSERT INTO pedidos(id_pedido, id_cliente, id_personal, fecha_pedido, total)
    VALUES(v_id_pedido, arg_id_cliente, arg_id_personal, SYSDATE, 0);
    
    IF arg_id_primer_plato IS NOT NULL THEN
        INSERT INTO detalle_pedido(id_pedido, id_plato, cantidad)
        VALUES(v_id_pedido, arg_id_primer_plato, 1);  
    END IF;

    IF arg_id_segundo_plato IS NOT NULL THEN
        INSERT INTO detalle_pedido(id_pedido, id_plato, cantidad)
        VALUES(v_id_pedido, arg_id_segundo_plato, 1);  
    END IF;

    UPDATE personal_servicio
    SET pedidos_activos = pedidos_activos + 1
    WHERE id_personal = arg_id_personal;
    COMMIT;

    
  
end;
>>>>>>> e6cdb817f49290ee4a337a2465d985d9b7a669ee
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites para cada una)
-- * P4.1
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 

CREATE OR REPLACE PROCEDURE reset_seq(p_seq_name VARCHAR2) IS
    l_val NUMBER;
BEGIN
    EXECUTE IMMEDIATE
    'SELECT ' || p_seq_name || '.nextval FROM dual' INTO l_val;
    EXECUTE IMMEDIATE
    'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY -' || l_val || ' MINVALUE 0';
    EXECUTE IMMEDIATE
    'SELECT ' || p_seq_name || '.nextval FROM dual' INTO l_val;
    EXECUTE IMMEDIATE
    'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY 1 MINVALUE 0';
END;
/

CREATE OR REPLACE PROCEDURE inicializa_test IS
BEGIN
    reset_seq('seq_pedidos');
    
    -- First delete from child tables, then parent tables (respect foreign keys)
    DELETE FROM detalle_pedido;
    DELETE FROM pedidos;
    DELETE FROM platos;
    DELETE FROM personal_servicio;
    DELETE FROM clientes;
    
    -- Insertar datos de prueba
    INSERT INTO clientes (id_cliente, nombre, apellido, telefono) VALUES (1, 'Pepe', 'Perez', '123456789');
    INSERT INTO clientes (id_cliente, nombre, apellido, telefono) VALUES (2, 'Ana', 'Garcia', '987654321');
    
    INSERT INTO personal_servicio (id_personal, nombre, apellido, pedidos_activos) VALUES (1, 'Carlos', 'Lopez', 0);
    INSERT INTO personal_servicio (id_personal, nombre, apellido, pedidos_activos) VALUES (2, 'Maria', 'Fernandez', 5);
    
    INSERT INTO platos (id_plato, nombre, precio, disponible) VALUES (1, 'Sopa', 10.0, 1); -- 1 = true
    INSERT INTO platos (id_plato, nombre, precio, disponible) VALUES (2, 'Pasta', 12.0, 1); -- 1 = true
    INSERT INTO platos (id_plato, nombre, precio, disponible) VALUES (3, 'Carne', 15.0, 0); -- 0 = false

    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE test_registrar_pedido IS
BEGIN
  -- Caso 1: Pedido correcto, se realiza
  BEGIN
    inicializa_test;
    
    DECLARE
        id_pedido_test INTEGER;
        pedido_activo_test_pre INTEGER; -- guardar cuántos pedidos activos tenía Carlos
    
    BEGIN
      -- Guardo valor previo de pedidos activos de Carlos
        SELECT pedidos_activos
        INTO pedido_activo_test_pre
        FROM personal_servicio
        WHERE id_personal=1;
    
        DBMS_OUTPUT.PUT_LINE('Test1: Se realiza un pedido con un primer y segundo plato disponible y personal con capacidad------------------');
        registrar_pedido(1, 1, 1, NULL); -- Cliente Pepe, personal Carlos, Primer pl Sopa y segundo Plato nulo
    
        SELECT MAX(id_pedido) -- pedido más reciente
        INTO id_pedido_test
        FROM pedidos
        WHERE id_cliente = 1 AND id_personal = 1;
    
        IF id_pedido_test IS NULL THEN
          DBMS_OUTPUT.PUT_LINE('No se ha realizado el pedido correctamente');
        END IF;
        
        -- Comprobar si la cantidad de pedidos activos del personal ha aumentado
        DECLARE
            pedido_activo_test INTEGER;
        BEGIN
            SELECT pedidos_activos
            INTO pedido_activo_test
            FROM personal_servicio
            WHERE id_personal=1;
        
            IF pedido_activo_test > pedido_activo_test_pre THEN
                DBMS_OUTPUT.PUT_LINE('Los pedidos activos han aumentado');
            ELSE
                DBMS_OUTPUT.PUT_LINE('No se ha registrado un pedido activo nuevo');
            END IF;    
            ROLLBACK;
        END;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Test2: Pedido vacío sin ningún plato que devuelve excepción -20002');
    
    BEGIN
        registrar_pedido(1, 1, NULL, NULL);
        ROLLBACK;    
        DBMS_OUTPUT.PUT_LINE('MAL: registra pedido sin primer plato ni segundo.');
    EXCEPTION
        WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            DBMS_OUTPUT.PUT_LINE('BIEN: pedido vacío.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('MAL: Da error pero no detecta platos vacíos.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        END IF;
    END;
    
    
    DBMS_OUTPUT.PUT_LINE('Test3: Pedido con plato inexistente que devuelve excepción -20004');
    BEGIN
        -- Escogeré un número aleatorio, por ejemplo, el 33
        registrar_pedido(1, 1, 33, NULL);
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN
            DBMS_OUTPUT.PUT_LINE('BIEN: pedido con plato inexistente ha generado el error -20004.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('MAL: Da error pero no detecta platos inexistentes.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Test4: Pedido que incluye un plato que ya no está disponible devuelve error -20001');
    BEGIN
        registrar_pedido(1, 1, 3, 2);
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('BIEN: pedido con plato no disponible ha generado el error -20001.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('MAL: Da error pero no detecta platos no disponibles.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Test5: Personal de servicio con ya 5 pedidos activos y se le asigna otro devuelve error -20003');
    BEGIN
        registrar_pedido(1, 2, 1, 2);
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
        IF SQLCODE = -20003 THEN
            DBMS_OUTPUT.PUT_LINE('BIEN: pedido con personal con más de 5 pedidos activos devuelve -20003.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('MAL: Da error pero no detecta que hay pedidos de más.');
            DBMS_OUTPUT.PUT_LINE('Error nro '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mensaje '||SQLERRM);
        END IF;
    END;
END;
/

<<<<<<< HEAD
SET SERVEROUTPUT ON;
EXEC inicializa_test;
EXEC test_registrar_pedido;
=======

set serveroutput on;
exec test_registrar_pedido;
>>>>>>> e6cdb817f49290ee4a337a2465d985d9b7a669ee
