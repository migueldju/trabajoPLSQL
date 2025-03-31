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
    disponible BOOLEAN DEFAULT TRUE
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
create or replace procedure registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) is

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
  
  primeroDisponible BOOLEAN;
  segundoDisponible BOOLEAN;
  primeroExiste BOOLEAN;
  segundoExiste BOOLEAN;
  
 begin
  IF arg_id_primer_plato = NULL AND arg_id_segundo_plato = NULL THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20002, 'El pedido debe
 contener al menos un plato.');
  OPEN pedidosPersonal;
  FETCH pedidosPersonal INTO nPedidosPersonal;
  IF nPedidosPersonal >= 5
  THEN
        CLOSE nPedidosPersonal;
        ROLLBACK;
        raise_application_error(-20003, 'El personal de servicio tiene demasiados
 pedidos');
    END IF;
    CLOSE nPedidosPersonal;
    
    IF arg_id_primer_plato != NULL THEN    
        OPEN disponibilidadPrimero;
        FETCH disponibilidadPrimero INTO primeroDisponible;
        IF disponibilidadPrimero%NOTFOUND;
                CLOSE disponibilidadPrimero;
                ROLLBACK; 
                RAISE_APPLICATION_ERROR(-20004, 'El primer plato seleccionado no existe.');
                END IF;
        IF primeroDisponible = FALSE THEN
                CLOSE disponibilidadPrimero;
                ROLLBACK; 
                RAISE_APPLICATION_ERROR(-20001, 'Uno de los platos seleccionados no está disponible.');
            END IF;
        CLOSE disponibilidadPrimero;
    END IF;
    IF arg_id_segundo_plato != NULL THEN 
        OPEN disponibilidadSegundo;
        FETCH disponibilidadSegundo INTO segundoDisponible;
        IF disponibilidadSegundo%NOTFOUND;
                CLOSE disponibilidadSegundo;
                ROLLBACK; 
                RAISE_APPLICATION_ERROR(-20004, 'El segundo plato seleccionado no existe.');
                END IF;
        IF segundoDisponible = FALSE THEN
                CLOSE disponibilidadSegundo;
                ROLLBACK; 
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

    
  
end;
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
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


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
    
    reset_seq('seq_pedidos');
        
  
    delete from Detalle_pedido;
    delete from Pedidos;
    delete from Platos;
    delete from Personal_servicio;
    delete from Clientes;
    
    -- Insertar datos de prueba
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (1, 'Pepe', 'Perez', '123456789');
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (2, 'Ana', 'Garcia', '987654321');
    
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (1, 'Carlos', 'Lopez', 0);
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (2, 'Maria', 'Fernandez', 5);
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, TRUE);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, TRUE);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, FALSE);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios

create or replace procedure test_registrar_pedido is
begin
	 
  --caso 1 Pedido correct, se realiza
  begin
    inicializa_test;
    
        declare
            id_pedido_test integer;
            pedido_activo_test_pre integer;--guardar cunatos pedidos activos tenia maria
        
        begin
        
        --Guardo valor previo de pedidos activos de maria
            select pedidos_activos
            into pedido_activo_test_pre
            from personal_servicio
            where id_personal=1;
        
            dbms_output.put_line('Test1: Se realiza un pedido con un primer y segundo plato disponible y personal con capacidad------------------');
            registrar_pedido(1, 1, 1, null); -- Cliente Pepe, personal Carlos, Primer pl Sopa y segundo Plato nulo
        
            select max(id_pedido) --pedido mas reciente
            into id_pedido_test
            from pedidos
            where id_cliente = 1 and id_personal =1;
        
            if id_pedido_test is null then
             dbms_output.put_line('No se ha realizado el pedido correctamente');
            end if;
            
        --Comprobar si la cantidad de personal ha aumentado
        --Comprobar pedido activos
            declare
                pedido_activo_test integer;
                
            begin
        
                select pedidos_activos
                into pedido_activo_test
                from personal_servicio
                where id_personal=1;
            
                if pedido_activo_test>pedido_activos_test_pre then
                    dbms_output.put_line('los pedidos activos han aumentado');
                else
                    dbms_output.put_line('no se ha registrado un pedido activo nuevo');
                end if;    
                rollback
            end;

        end;
        
        dbms_output.put_line('Test2 Pedido vacio sin ningun plato que devuelve excepcions -20002');
        
        begin
            registrar_pedido(1,1, null, null);
            rollback;    
            dbms_output.put_line('MAL: registra pedido sin primer plato ni segundo.');
        exception
            when others then
            if SQLCODE = -20002 then
                dbms_output.put_line('BIEN: pedido vacio.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            else
                dbms_output.put_line('MAL: Da error pero no detecta platos vacios.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            end if;
        end;
        
        
        dbms_output.put_line('Test3 Pedido con plato inexistente que devuelve excepcion -20004');
        begin
            --Registrare escogere un numero aleatorio, por ejemplo el 33
            registrar_pedido(1,1,33, null);
            rollback
        exception
            when others then
            if SQLCODE = -20004 then
                dbms_output.put_line('BIEN: pedido con plato inexistente ha generado el error -20004.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            else
                dbms_output.put_line('MAL: Da error pero no detecta platos inexistente.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            end if;
        end;
        
        dbms_output.put_line('Test4 Pedido que incluye un plato que ya no esta disponible delvuelve error -20001');
        begin
            registrar_pedido(1,1,3,2);
            rollback;
        exception
            when others then
            if SQLCODE = -20001 then
                dbms_output.put_line('BIEN: pedido con plato no disponible ha generado el error -20001.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            else
                dbms_output.put_line('MAL: Da error pero no detecta platos inexistentes.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            end if;
            
        end;
        
        dbms_output.put_line('Test5 Personal de servicio con ya 5 pedidos activos y se le asigna otro devuelve error -20003');
        begin
            registrar_pedido(1,2, 1,2);
            rollback;
        exception
            when others then
            if SQLCODE = -20003 then
                dbms_output.put_line('BIEN: pedido con personal con mas de 5 pedidos activos devuelve -20003.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            else
                dbms_output.put_line('MAL: Da error pero no detecta que hay pedidos de mas.');
                dbms_output.put_line('Error nro '||SQLCODE);
                dbms_output.put_line('Mensaje '||SQLERRM);
            end if;
        end
        
        
  
  -- Idem para el resto de casos

  /* - Si se realiza un pedido vac´ıo (sin platos) devuelve el error -200002.
     - Si se realiza un pedido con un plato que no existe devuelve en error -20004.
     - Si se realiza un pedido que incluye un plato que no est´a ya disponible devuelve el error -20001.
     - Personal de servicio ya tiene 5 pedidos activos y se le asigna otro pedido devuelve el error -20003
     - ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento
*/
  
end;

end;
/


set serveroutput on;
exec test_registrar_pedido;
