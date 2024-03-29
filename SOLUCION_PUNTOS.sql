
--- VISTA 2
CREATE OR REPLACE VIEW plan_mantenimiento_detallado 
AS
select 
A.TIPO_MANTENIMIENTO AS KILOMETRAJE,
c.nombre AS ITEM

from MANTENIMIENTOS A INNER JOIN DETALLE_MANTENIMIENTOS B ON A.ID=B.MANTENIMIENTO_ID
INNER JOIN MANTENIMIENTO_ITEMS C ON C.ID = b.mantenimiento_item_id
ORDER BY a.id;

--SELECT * FROM plan_mantenimiento_detallado
--where KILOMETRAJE like '%10,000%';

--PUNTO 3 

CREATE OR REPLACE PROCEDURE Programar_mantenimiento ( VEHICULO_ID IN INTEGER)
AS 
KILOMETROS_3 number;
KILOMETROS_2 number;
RESTA number;
FECHA DATE;
ID_VEHICULO INTEGER;
ID_MANTENIMIENTO INTEGER :=0;
EMPLEADO INTEGER;
MAN_ID INTEGER;
IDENTIFICADOR2 number:=1;
NUMERO2 number:=1;
I NUMBER:=1;
CANTIDAD NUMBER;

BEGIN 
IF VEHICULO_ID <=0
    THEN DBMS_OUTPUT.PUT_LINE('ID NO VALIDO');
END IF;

SELECT A.ID , A.KILOMETRAJE ,b.mantenimiento_id, b.empleados_id INTO ID_VEHICULO, KILOMETROS_3,ID_MANTENIMIENTO,EMPLEADO
FROM VEHICULOS A INNER JOIN PROGRAMACION_MANTENIMIENTOS B ON A.ID=B.INVENTARIO_VEHICULOS_ID
WHERE B.INVENTARIO_VEHICULOS_ID=VEHICULO_ID
AND  B.FECHA= (SELECT MAX (FECHA) from PROGRAMACION_MANTENIMIENTOS where INVENTARIO_VEHICULOS_ID=VEHICULO_ID);

MAN_ID := ID_MANTENIMIENTO+1;
     SELECT KILOMETROS  INTO KILOMETROS_2 FROM MANTENIMIENTOS WHERE ID=MAN_ID;
     RESTA := KILOMETROS_2-KILOMETROS_3;
    IF RESTA< 200 THEN
      FECHA:= SYSDATE+2;
        INSERT INTO PROGRAMACION_MANTENIMIENTOS(ID,MANTENIMIENTO_ID,EMPLEADOS_ID,INVENTARIO_VEHICULOS_ID,FECHA)
        VALUES(ID_PROGRAMACION_MAN.nextval,MAN_ID,EMPLEADO,VEHICULO_ID,FECHA);
        SELECT COUNT(1) INTO CANTIDAD  FROM detalle_mantenimientos WHERE mantenimiento_id= MAN_ID;
        FOR I IN 1..CANTIDAD LOOP        
        SELECT NUMERO2, IDENTIFICADOR2 INTO NUMERO2, IDENTIFICADOR2 
            FROM (SELECT mantenimiento_item_id AS NUMERO2,  ROWNUM AS IDENTIFICADOR2  FROM detalle_mantenimientos WHERE MANTENIMIENTO_ID=MAN_ID) A WHERE IDENTIFICADOR2 = I;
            
            INSERT INTO DETALLE_PROGRAMACION_MANTENIMIENTOS(ID,PROGRAMACION_MANTENIMIENTOS_ID,DETALLE_MANTENIMIENTOS_ID,ESTADO,OBSERVACION)
            VALUES(ID_DETA_PRO_MAN.nextval,MAN_ID,NUMERO2,'PENDIENTE',NULL);        
         END LOOP;        
      END IF;
END;

EXEC Programar_mantenimiento(9);

---PUNTO 4

CREATE OR REPLACE TRIGGER KILOMETROS
    AFTER UPDATE ON VEHICULOS
    
    BEGIN
       Programar_mantenimiento(10);
    END;  
 

--PUNTO 5
/
create or replace procedure recalcular_tarifas
as
IDENTIFICADOR number:=1;
NUMERO number:=1;
IDENTIFICADOR2 number:=1;
NUMERO2 number:=1;
I NUMBER:=1;
A INTEGER :=1;
CENTRO_RECIB_ID INTEGER;
CIUDAD_ID INTEGER;
TOTAL_CENTROS INTEGER;
TOTAL_CIUDADES INTEGER;
PRECIO_KILO1 NUMBER;
--DROP_S VARCHAR2 (1000);
BEGIN
execute immediate 'TRUNCATE TABLE COTIZACION';
execute immediate 'ALTER SEQUENCE ID_COTIZACION MINVALUE 0';
--execute immediate DROP_S;

SELECT COUNT(1) TOTAL INTO TOTAL_CENTROS  FROM CENTRO_CARGAS; 
SELECT COUNT(1) TOTAL INTO TOTAL_CIUDADES  FROM CODIGOS_POSTAL; 
FOR I IN 1..TOTAL_CENTROS LOOP
   
     SELECT NUMERO2, IDENTIFICADOR2 INTO NUMERO2, IDENTIFICADOR2 
            FROM (SELECT ID AS NUMERO2, ROWNUM AS IDENTIFICADOR2  FROM CENTRO_CARGAS) A WHERE IDENTIFICADOR2 = I;
            
       FOR A IN 1..TOTAL_CIUDADES LOOP
            SELECT NUMERO, IDENTIFICADOR INTO NUMERO, IDENTIFICADOR 
            FROM (SELECT ID AS NUMERO, ROWNUM AS IDENTIFICADOR  FROM CODIGOS_POSTAL) A WHERE IDENTIFICADOR = A;  
            PRECIO_KILO1 := DBMS_RANDOM.VALUE(400,1500);
            INSERT INTO COTIZACION(ID,CENTRO_CARGAS_ID,ciudad_id,PRECIO_KILO)
            VALUES(ID_COTIZACION.nextval,NUMERO2,NUMERO,PRECIO_KILO1);
        END LOOP;
END LOOP;
END;
/

EXEC recalcular_tarifas;
/

--PUNTO 6

CREATE OR REPLACE VIEW PRECIO_POR_KILO
AS
SELECT E.ID ORIGEN ,F.NOMBRE NOMBRE_ORIGEN,  A.CIUDAD_ID DESTINO,C.NOMBRE NOMBRE_DESTINO,A.PRECIO_KILO PRECIO 
FROM COTIZACION A INNER JOIN CODIGOS_POSTAL B ON A.CIUDAD_ID=B.ID
                  INNER JOIN CIUDADES C ON B.CIUDADES_ID = C.ID
                  INNER JOIN CENTRO_CARGAS D ON A.CENTRO_CARGAS_ID = D.ID
                  INNER JOIN CODIGOS_POSTAL E ON E.ID = D.CODIGOS_POSTAL_ID
                  INNER JOIN CIUDADES F ON F.ID = E.CIUDADES_ID;


--select * from PRECIO_POR_KILO;


--PUNTO 7

CREATE OR REPLACE PROCEDURE calcular_peso_volumetrico 
AS
REGISTROS number :=1;
ANCHO number:=1;
LARGO number:=1;
ALTO number:=1;
IDENTIFICADOR number:=1;
NUMERO number:=1;
PESO_VOLUMEN1 number:=1;
I NUMBER:=1;
A INTEGER :=1;
BEGIN 
SELECT COUNT(1) INTO REGISTROS  FROM DESPACHOS;
WHILE (A <= REGISTROS) LOOP
    SELECT NUMERO, IDENTIFICADOR INTO NUMERO, IDENTIFICADOR FROM (SELECT ID AS NUMERO, ROWNUM AS IDENTIFICADOR  FROM DESPACHOS) A WHERE IDENTIFICADOR = A ; 
    SELECT (ANCHO*LARGO*ALTO)*400 INTO PESO_VOLUMEN1 FROM DESPACHOS WHERE ID = NUMERO ; 
    UPDATE DESPACHOS 
    SET
    PESO_VOLUMEN = PESO_VOLUMEN1   
    WHERE ID=NUMERO;
    A := A + 1 ;
END LOOP;
END;
/
EXEC calcular_peso_volumetrico;
/--VALIDAMOS

--UPDATE DESPACHOS
--SET PESO_VOLUMEN=0;

--SELECT * FROM DESPACHOS order by id asc;

--PUNTO 8
CREATE OR REPLACE FUNCTION PUNTO8 (PESO_REAL NUMBER, PESO_VOLUMEN NUMBER,CENTRO_RECIBO NUMBER, CIUDAD_DESTINO NUMBER) 
RETURN NUMBER
IS
PRECIO1 NUMBER :=1;
BEGIN 

IF PESO_REAL > 0 AND PESO_VOLUMEN > 0  THEN
        SELECT PRECIO INTO PRECIO1 FROM PRECIO_POR_KILO
        WHERE ORIGEN =CENTRO_RECIBO AND DESTINO = CIUDAD_DESTINO AND rownum = 1;
    IF PESO_REAL > PESO_VOLUMEN THEN         
        RETURN(PESO_REAL * PRECIO1);
     ELSE
        RETURN(PESO_VOLUMEN*PRECIO1);
    END IF;
ELSE
DBMS_OUTPUT.PUT_LINE('DATOS INCORRECTOS');
END IF;
END;
/
SELECT PUNTO8(100,50,630001,521548) AS Valor FROM DUAL;


--PUNTO 9 
CREATE OR REPLACE PROCEDURE calcular_fletes 
AS
IDENTIFICADOR2 number:=1;
NUMERO2 number:=1;
PESO_REAL number:=1;
PESO_VOLUMEN number:=1;
ORIGEN number:=1;
DESTINO number:=1;
I NUMBER:=1;
REGISTROS NUMBER;
VALOR NUMBER;
BEGIN
SELECT COUNT(1) INTO REGISTROS  FROM DESPACHOS
WHERE VALOR_SERVICIO=0;
FOR I IN 1..REGISTROS LOOP  

 SELECT NUMERO2, IDENTIFICADOR2,PESO, PESO_VOLUMEN, CIUDAD_ORIGEN_ID, CIUDAD_DESTINO_ID  INTO NUMERO2, IDENTIFICADOR2, PESO_REAL, PESO_VOLUMEN, ORIGEN,DESTINO 
    FROM (SELECT ID AS NUMERO2, ROWNUM AS IDENTIFICADOR2, PESO, PESO_VOLUMEN, CIUDAD_ORIGEN_ID, CIUDAD_DESTINO_ID  FROM DESPACHOS
     WHERE VALOR_SERVICIO=0) A WHERE IDENTIFICADOR2 = I;     
     SELECT PUNTO8(PESO_REAL,PESO_VOLUMEN,ORIGEN,DESTINO) INTO VALOR FROM DUAL; 
     
     UPDATE DESPACHOS
    SET VALOR_SERVICIO = VALOR
    WHERE ID = NUMERO2;  
     
END LOOP;
END;
            
 EXEC calcular_fletes;    
 
 --SELECT ID AS NUMERO2, ROWNUM AS IDENTIFICADOR2, PESO, PESO_VOLUMEN, CIUDAD_ORIGEN_ID, CIUDAD_DESTINO_ID, VALOR_SERVICIO  FROM DESPACHOS
     --WHERE  id =198;  
      
   
-------PUNTO 10
CREATE OR REPLACE FUNCTION CALCULAR_CAJAS_NECESARIAS (ITEM NUMBER, CAJAS_GRANDES NUMBER, CAJAS_PEQUE�AS NUMBER) 
RETURN NUMBER
IS
NUMERO NUMBER;
MODULO NUMBER;
TOTAL NUMBER;
NUMERO2 NUMBER;
RESTA2 NUMBER;
TOTAL2 NUMBER;
BEGIN
NUMERO := ROUND(ITEM/5,0);
MODULO := MOD(ITEM,5);
IF NUMERO <= CAJAS_GRANDES THEN  
    IF MODULO <= CAJAS_PEQUE�AS THEN            
       TOTAL:= NUMERO+MODULO; 
       RETURN(TOTAL);        
     ELSE 
        TOTAL:= -1;
        RETURN(TOTAL);
     END IF;
ELSE     
    NUMERO2:= CAJAS_GRANDES *5;
    RESTA2 := ITEM-NUMERO2;
    IF RESTA2<= CAJAS_PEQUE�AS THEN
    TOTAL2:= CAJAS_GRANDES+RESTA2;
       RETURN(TOTAL2);
    ELSE
        TOTAL:= -1;
        RETURN(TOTAL);   
    END IF;
END IF;
END;

SELECT CALCULAR_CAJAS_NECESARIAS(16,5,4) AS CAJAS FROM DUAL;



            