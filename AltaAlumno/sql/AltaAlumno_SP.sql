DROP TABLE matriculas CASCADE CONSTRAINTS;
DROP TABLE asignaturas CASCADE CONSTRAINTS;
DROP TABLE grupos CASCADE CONSTRAINTS;

CREATE TABLE asignaturas(
	nombre	  VARCHAR(10) PRIMARY KEY,
	nCreditos INTEGER
);

INSERT INTO asignaturas VALUES( 'FPROG', 9);
INSERT INTO asignaturas VALUES( 'OFIM', 6);

CREATE TABLE grupos(
	idGrupo 	INTEGER,
	asignatura	VARCHAR(10) REFERENCES asignaturas,
	plazasLibres	INTEGER,
	PRIMARY KEY( idGrupo, asignatura)
);

--Hacemos grupos de 4 alumnos para no tener que insertar muchas filas en
--la tabla matricula
INSERT INTO grupos VALUES( 1, 'FPROG', 4);
INSERT INTO grupos VALUES( 1, 'OFIM',  4);
INSERT INTO grupos VALUES( 2, 'FPROG', 4);
INSERT INTO grupos VALUES( 2, 'OFIM',  4);
INSERT INTO grupos VALUES( 10, 'OFIM',  4);


CREATE TABLE matriculas(
	idMatricula integer   PRIMARY KEY,
	alumno      VARCHAR(20) NOT NULL,
  asignatura  VARCHAR(10) NOT NULL,
  grupo	    INTEGER  NOT NULL,
  FOREIGN KEY( grupo, asignatura) REFERENCES grupos
);

drop sequence seq_matricula;
create sequence seq_matricula;

--Llenamos el grupo 1 de ofimatica
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'PEPE', 'OFIM', 1);
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'ANA', 'OFIM', 1);
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'JUAN', 'OFIM', 1);
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'LUIS', 'OFIM', 1);

UPDATE grupos SET plazasLibres=plazasLibres-4
WHERE asignatura='OFIM' AND idgrupo=1;

--Dejamos 1 plaza libre en el grupo 2 de ofimatica
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'ANTONIO', 'OFIM', 2);
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'MERCEDES', 'OFIM',  2);
INSERT INTO matriculas VALUES ( seq_matricula.nextval, 'JESUS', 'OFIM', 2);

UPDATE grupos SET plazasLibres=plazasLibres-3
WHERE asignatura='OFIM' AND idgrupo=2;

--Los grupos de FPROG quedan vacios (con sitio de sobra)

commit;

create or replace procedure matricular (arg_alumno matriculas.alumno%type,
  arg_asig matriculas.asignatura%type, arg_grupo matriculas.grupo%type ) is
  
  SIN_PLAZAS      exception;
  PRAGMA EXCEPTION_INIT(SIN_PLAZAS,             -20001);
  NO_EXISTE_ASIG_GRUPO exception;
  PRAGMA EXCEPTION_INIT(NO_EXISTE_ASIG_GRUPO,    -20002);
  
  FK_VIOLATED           exception; --ORA-02291: integrity constraint (la que sea) violated - parent key not found
  PRAGMA EXCEPTION_INIT(FK_VIOLATED, -2291);

begin  
  begin
    INSERT INTO matriculas (idMatricula, alumno, asignatura, grupo) 
      VALUES (seq_matricula.nextval, arg_alumno, arg_asig, arg_grupo);
      
     UPDATE grupos SET plazasLibres=plazasLibres-1
     WHERE idGrupo=arg_grupo AND asignatura=arg_asig AND plazasLibres>0;
      
    if sql%rowcount = 0 then    
      raise_application_error(-20001, 
        'No quedan plazas libres en el grupo '||arg_grupo||
        ' de la asignatura '||arg_asig||'.');
    end if;
    
    commit;
  exception
    when FK_VIOLATED then
      raise_application_error(-20002, 
            'No existe la combinacion '||arg_asig||'-grupo '||arg_grupo||'.');
  end;
exception
  when others then
      rollback;
      raise;
end;
/
exit;

set serveroutput on

create or replace procedure test_alta_alumno is
begin
  
  --Caso 1: Matriculamos en el grupo lleno  
  begin
    matricular('Julian','OFIM',1);
    dbms_output.put_line('Mal no detecta SIN_PLAZAS');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('Detecta OK SIN_PLAZAS: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta SIN_PLAZAS: '||sqlerrm);
      end if;
  end;
  
  --Caso 2: Matricular en asignatura inexistente
   begin
    matricular('Pedro','ALGEBRA',1);
    dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso asignatura no existe');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('Detecta OK NO_EXISTE_ASIG_GRUPO caso asignatura no existe: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso asignatura no existe'||sqlerrm);
      end if;
  end;
  
  --Caso 3: No existe el grupo
  begin
    matricular('Pedro','OFIM',3);
    dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso grupo no existe');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('Detecta OK NO_EXISTE_ASIG_GRUPO caso grupo no existe: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso grupo no existe: '||sqlerrm);
      end if;
  end;
  
  --Caso 4: No existe la combinacion
  begin
    matricular('Pedro','FPROG',10);
    dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso combinaci�n no existe');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('Detecta OK NO_EXISTE_ASIG_GRUPO caso combinaci�n no existe: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta NO_EXISTE_ASIG_GRUPO caso combinaci�n no existe: '||sqlerrm);
      end if;
  end;
    
  --Caso 5: Todo OK
  declare
    varContenidoReal varchar(500);
    varContenidoEsperado    varchar(500):=    
    '1FPROG312Pedro#'||
    '1OFIM01PEPE#1OFIM02ANA#1OFIM03JUAN#1OFIM04LUIS#'||
    '2FPROG4#'||
    '2OFIM15ANTONIO#2OFIM16MERCEDES#2OFIM17JESUS#'||
    '10OFIM4';
    
      
  begin
    matricular('Pedro','FPROG',1);
    rollback; --por si se olvida commit de matricular
    
    SELECT listagg( idgrupo||grupos.asignatura||plazaslibres||idmatricula||alumno, '#')
        within group (order by idGrupo, grupos.asignatura) 
    into varContenidoReal
    FROM grupos left join matriculas on(matriculas.grupo=grupos.idGrupo
           and matriculas.asignatura=grupos.asignatura);
    
    
    if varContenidoReal=varContenidoEsperado then
      dbms_output.put_line('BIEN: si modifica bien la BD.'); 
    else
      dbms_output.put_line('Mal: no modifica bien la BD.'); 
      dbms_output.put_line('Contenido real:     '||varContenidoReal); 
      dbms_output.put_line('Contenido esperado: '||varContenidoEsperado); 
    end if;
    
  exception
    when others then
      dbms_output.put_line('Mal caso todo OK: '||sqlerrm);
  end;
  
end;
/

begin
  test_alta_alumno;
end;
/
