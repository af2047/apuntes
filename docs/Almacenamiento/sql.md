## SQL vs noSQL

Las bases de datos se dividen en

* relacionales (SQL): almacenan la información en tablas relacionadas entre sí
* no relacionales (noSQL)

Todas las bases de datos relacionales se pueden manejar con el lenguaje SQL (Structured Query Language). Hay [diferencias en la sintaxis](http://troels.arvin.dk/db/rdbms/#insert) de SQL dependiendo del modelo de base de datos que estemos usando.

## Google Cloud

Estos apuntes son para la base de datos de Oracle, que utilizamos en 1º. En BigQuery hay varias diferencias:

* BigQuery usa una versión de SQL que llaman "Standard SQL". Algunos de los comandos son diferentes, como las conversiones de tipos. Se puede usar SQL normal seleccionando `More -> Query Settings -> Legacy SQL` en el editor de queries
* Los tipos de variable son diferentes: `STRING`, `INT`, `NUMERIC`, `BOOL`, `DATE` / `DATETIME`, y [otros](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types)

## Dónde practicar

* [LiveSQL](https://livesql.oracle.com) - entorno interactivo de Oracle, con tutoriales
  * para ver el estado actual de la base de datos, pulsar el botón `Find`
* [SQLFiddle](http://sqlfiddle.com/#!4) - otro entorno interactivo, va más fluido que el de Oracle. Utilizar el panel de la izquierda para crear las tablas e insertar datos, el de la derecha es sólo para queries
* [Imagen de VirtualBox](https://www.oracle.com/database/technologies/databaseappdev-vm.html#license-lightbox) - como LA MÁQUINA de Susy pero cien veces más rápida
* Instalación local: [base de datos](https://www.oracle.com/es/database/technologies/xe-downloads.html) y [SQL developer](https://www.oracle.com/tools/downloads/sqldev-downloads.html)
  * en SQL Developer se puede ver el estado actual de todas las tablas en el panel Conexiones, a la izquierda de la pantalla. Si no aparece, ir al menú Ventana -> Restaurar configuración de fábrica.

SQL Developer y LiveSQL ejecutan sólo el código seleccionado. Si no hay nada seleccionado, ejecutan el script entero.

## Ejemplos

* **Tabla de ejemplo**: http://sqlfiddle.com/#!4/5497c. Los ejemplos en este documento se pueden ejecutar sobre esta tabla.
* **Ejercicio de médicos y pacientes de Susy**: http://sqlfiddle.com/#!4/4e935d3
* **SQLZoo**: https://sqlzoo.net/. Ejercicios para practicar queries

## Sintaxis

* Los identificadores (nombres de tablas, columnas, etc.) deben empezar con una letra y pueden contener letras, números y barras bajas, pero no espacios ni puntos. 
* Los identificadores no distinguen entre mayúsculas y minúsculas, pero internamente están siempre en mayúsculas; esto es importante a la hora de usar ``SELECT``. Los valores contenidos en las tablas sí distinguen entre mayúsculas y minúsculas. 
* La convención que usa casi todo el mundo es escribir los comandos en mayúsculas y todo lo demás en minúsculas. La que usa Susy es poner los nombres de tabla en mayúsculas y lo demás en minúsculas.
* Poner un punto y coma después de cada frase.
* Al insertar VARCHAR2 y DATE **usar comillas simples** (``'``), no dobles.
* Comentarios: ``--`` (una línea) y ``/* */`` (varias líneas). Si un comentario es lo último que hay en un archivo, Oracle va a darnos un error.

## Crear tablas

Usar ``CREATE TABLE``. 

```sql
    CREATE TABLE empresas (
    nombre VARCHAR2(20) PRIMARY KEY
    );

    CREATE TABLE empleados (
    dni NUMBER(8) PRIMARY KEY,
    nombre VARCHAR2(20) NOT NULL,
    empresa VARCHAR2(20) REFERENCES empresas(nombre),
    sueldo NUMBER(6) NOT NULL
    );
```

Las columnas de las tablas se escriben separadas por comas. Escribir primero el nombre, seguido del tipo y las constraints como ``NOT NULL``.

Para ver las columnas que contiene una tabla usar ``DESCRIBE tabla``, y para ver todos sus elementos, ``SELECT * FROM tabla``.

La tabla ``user_tables`` es una tabla interna de Oracle que contiene los nombres y datos de todas las tablas que hemos definido. Para ver una lista de todas nuestras tablas, usar ``SELECT table_name FROM user_tables``.

Una tabla se puede eliminar con ``DROP TABLE tabla``. Si la tabla contiene constraints, hay que usar ``DROP TABLE tabla CASCADE CONSTRAINTS``. Las tablas sólo se pueden eliminar una a una; para borrar todas nuestras tablas a la vez seguir estos pasos:

* Ejecutar el comando ``SELECT 'DROP TABLE "' || TABLE_NAME || '" CASCADE CONSTRAINTS;' FROM user_tables;``
* Esta query nos da como resultado una serie de comandos, cada uno de los cuales elimina una tabla. Copiar y pegar todos estos comandos y ejecutarlos para eliminar todas las tablas

## Modificar tablas

Para añadir, modificar o eliminar columnas o constraints, usar ``ALTER TABLE`` con ``ADD``, ``MODIFY``, ``DROP`` o ``RENAME``. 

Algunos de estos comandos no funcionarán si la tabla que queremos modificar ya contiene datos. Por ejemplo, sólo podríamos añadir columnas que fueran ``null``.

```sql
    -- Añadir columna
    ALTER TABLE empleados ADD empleo VARCHAR2(100);

    -- Modificar tipo de datos
    ALTER TABLE empleados MODIFY dni VARCHAR2(9);

    -- Eliminar columna
    ALTER TABLE empleados DROP COLUMN nombre;

    -- Eliminar constraint (sólo si la declaramos fuera de línea con un nombre)
    ALTER TABLE ejemplo DROP CONSTRAINT const_name;

    -- Renombrar
    ALTER TABLE empleados RENAME COLUMN sueldo TO salario;
```

## Obtener información sobre las tablas

Lista de todas las tablas: ``SELECT table_name FROM user_tables;``

Todas las propiedades de todas las tablas: ``SELECT * FROM user_tables;``

## Tipos de joins

Hay cuatro tipos de joins:

* ``INNER JOIN``: muestra sólo los elementos en los que la condición de unión se cumple.
* ``FULL JOIN``: muestra todas las columnas de todas las tablas, aunque la condición de unión no se cumpla.
* ``LEFT JOIN``: muestra todas las columnas de la tabla izquierda, y sólo las de la tabla derecha que cumplen la condición de unión.
* ``RIGHT JOIN``: muestra todas las columnas de la tabla derecha, y sólo las de la tabla izquierda que cumplen la condición de unión.

El join por defecto es ``INNER JOIN``. En los otros tres tipos (outer joins), cuando la condición no se cumple para una fila, esa fila se completa con ``null``.
## Constraints

Las constraints imponen condiciones a los valores que puede contener una columna. Se pueden declarar en línea o fuera de línea:

```sql
    -- Constraint en línea
    dni NUMBER(8) PRIMARY KEY

    -- Constraint fuera de línea (abreviada)
    dni NUMBER(8),
    PRIMARY KEY (dni)

    -- Constraint fuera de línea (con nombre)
    dni NUMBER(8),
    CONSTRAINT pk_dni PRIMARY KEY (dni)
```

Las constraints fuera de línea pueden tener nombre. Estos nombres nos permiten seleccionar la constraint si queremos modificarla o eliminarla posteriormente. No puede haber dos constraints con el mismo nombre.

Las constraints sólo se pueden usar dentro de un ``CREATE TABLE``, ``ALTER TABLE``, ``CREATE VIEW`` O ``ALTER VIEW``.

Hay seis tipos, sólo desarrollo los que hemos visto en clase:

#### primary key

Marca la columna como clave primaria.

La clave primaria debe ser única, pero se puede crear una PK múltiple con ``PRIMARY KEY (columna1, columna2)``. Esto sólo funciona con notación fuera de línea.

#### foreign key

Indica que la columna proviene de otra tabla. La tabla de origen se indica con ``REFERENCES``:

```sql
    -- Podemos omitir el tipo de dato, porque Oracle lo copiará de la tabla origen
    cod_empresa REFERENCES empresas (cod_empresa)

    -- Si la columna tiene el mismo nombre en ambas tablas, no es necesario indicarlo.
    cod_empresa REFERENCES empresas

    -- Si queremos hacerlo fuera de línea:
    COD_EMPRESA number,
    CONSTRAINT fk_tabla1_cod_empresa FOREIGN KEY (cod_empresa) REFERENCES empresas
    -- Tener en cuenta que
    -- 1. hay que declarar la clave antes de aplicar la constraint
    -- 2. el código de constraint debe ser siempre único, por eso añadimos el nombre de la tabla actual
    -- 3. al igual que en el caso anterior, el nombre de columna se puede omitir, pero sólo si es el mismo nombre en ambas tablas
```

Las FK pueden ser null. Más información sobre interacciones entre FK y otras constraints: https://docs.oracle.com/cd/B28359_01/appdev.111/b28424/adfns_constraints.htm#sthref549

#### not null

Indica que el valor de la columna es obligatorio y no se puede dejar en blanco. Esta constraint siempre se tiene que declarar con notación en línea.

```sql
    nombre VARCHAR2(20) NOT NULL
```

Todas las PK son también not null, y no hay que indicarlo manualmente.

#### unique

Indica que la columna no puede contener valores repetidos. Todas las primary key son unique, y no es necesario indicarlo.

```sql
    correo_electronico VARCHAR2(50) UNIQUE
```

## Tipos de datos

Los tipos de datos son diferentes en cada modelo de base de datos. Los que vamos a utilizar son:

* ``VARCHAR2(n)``: texto con un tamaño máximo de n bytes (n letras, excepto si utilizamos caracteres especiales). Utilizarlo siempre en vez de ``CHAR`` o ``VARCHAR``. El valor máximo de n es 4000, para datos más grandes usar [tipos LOB](https://docs.oracle.com/cd/B28359_01/server.111/b28318/datatype.htm#CNCPT513).
* ``NUMBER(n, m)``: almacena números. n es el total de cifras (incluyendo decimales), y m el número de decimales.
* ``DATE``: almacena fecha y hora. Para introducirlas usar el formato ``TO_DATE('24-01-1548', 'DD-MM-YYYY``. [Manual de la función TO_DATE](https://docs.oracle.com/cd/B19306_01/server.102/b14200/functions183.htm).
* [Lista completa de tipos](https://docs.oracle.com/cd/B28359_01/server.111/b28318/datatype.htm#i2093)


## Añadir datos

Usar ``INSERT INTO tabla (columna1, columna2, ...) VALUES (valor1, valor2, ...);``.

```sql
    INSERT INTO empleados (dni, nombre, empresa, sueldo) 
        VALUES (53845739, 'Pablo', 'Google', 5000);
```

La lista de columnas se puede omitir si damos los valores en el mismo orden en que declaramos las columnas al crear la tabla.

```sql
    INSERT INTO empleados VALUES (3823734, 'Marcos', 'Amazon', 5500);
```

 Se puede insertar varios valores a la vez con ``INSERT ALL``. No ahorra nada de tiempo al escribirlo, pero es más eficiente que enviar los comandos uno a uno. Al final de un ``INSERT ALL`` es obligatorio incluir un ``SELECT``; la opción más común es usar ``SELECT * FROM dual``, que no hace nada. Los valores que se insertan van todos seguidos, sin coma o punto y coma.

```sql
    INSERT ALL
        INTO empleados (dni, nombre, empresa, sueldo) 
            VALUES (53845739, 'Pablo', 'Google', 5000)
        INTO empleados VALUES (3823734, 'Marcos', 'Amazon', 5500)
    SELECT * FROM DUAL;
```

## Modificar datos

``UPDATE`` permite cambiar datos ya introducidos en la tabla, y ``DELETE`` se usa para eliminarlos. Por defecto se aplican a todas las filas de la tabla; también se pueden combinar con ``WHERE`` si sólo queremos que afecten a algunas filas.

```sql
    UPDATE empleados SET sueldo = sueldo + 1000;
    DELETE FROM empleados WHERE empresa = 'Google';
```

## Selecciones

El comando ``SELECT ... FROM ...`` nos permite seleccionar los elementos que cumplan una condición dada. 

```sql
    SELECT * FROM empleados;
```

Se pueden pasar varias cláusulas adicionales, **en este orden**: ``SELECT DISTINCT ... FROM ... JOIN ... WHERE ... GROUP BY ... ORDER BY ...``. La cláusula FROM es obligatoria, todas las demás son opcionales.

```sql
    SELECT DISTINCT nombre, empresa FROM empleados
    WHERE sueldo > 2000 GROUP BY empresa, nombre ORDER BY nombre;
```

* ``DISTINCT``: no muestra los resultados repetidos.
* ``JOIN``: se utiliza para enlazar datos que están en tablas distintas pero comparten algún campo. [Ver abajo](#joins)
* ``WHERE``: muestra sólo los resultados que cumplen una condición. [Ver abajo](#condicionales)
* ``GROUP BY``: muestra los resultados agrupados según los valores únicos de una de las columnas.
* ``ORDER BY``: muestra los resultados ordenados según los valores de una o varias columnas. 

Se le pueden pasar dos parámetros adicionales: 
  * ``ASC`` ó ``DESC`` (orden ascendiente o descendiente, por defecto ``ASC``)
  * ``NULLS FIRST`` ó ``NULLS LAST`` (por defecto ``NULLS LAST``)

Lista de todas las tablas: ``SELECT table_name FROM user_tables;``

El comando ``SELECT`` se puede anidar.

## Combinación de selecciones

En SQL podemos combinar los resultados de varias selecciones. Para que se puedan aplicar estas operaciones, los resultados deben tener el mismo número de columnas, y estas columnas deben tener tipos compatibles.

* ``selección1 UNION selección2`` devuelve la unión de las selecciones: todos los elementos que están al menos en una de ellas. Si hay filas que están en ambas selecciones sólo devuelve una; si queremos que muestre las dos hay que usar ``UNION ALL``.
* ``selección1 INTERSECT selección2`` devuelve la intersección de las selecciones: los elementos que están en ambas.
* ``selección1 MINUS selección2`` devuelve los elementos que están en la primera selección pero no en la segunda.

## Condicionales

Los condicionales en SQL se representan con la cláusula ``WHERE``. Se puede utilizar dentro de un comando ``SELECT``, ``INSERT``, ``UPDATE`` o ``DELETE``.

La sintaxis del comando es ``WHERE condición``, donde la condición puede tomar una de estas formas: ``sueldo = 1000``, ``sueldo <= 1000`` (ó ``>=``) y ``sueldo BETWEEN 2000 AND 2500``.

```sql
    SELECT nombre, sueldo FROM empleados WHERE sueldo >= 5000;
```

Podemos combinar varias condiciones usando ``AND``, ``OR`` y ``NOT``. Si tenemos más de dos condiciones es aconsejable usar paréntesis para dejar claro en qué orden queremos que se combinen.

```sql
    SELECT nombre, sueldo FROM empleados WHERE (sueldo > 3000) AND (NOT empresa = 'Google');
```

## Group by

El comando ``GROUP BY columna`` agrupa en una sola fila todos los elementos que comparten el mismo valor de la columna.

Como este comando va a agrupar varias filas en una, tenemos que utilizar alguna función de agregación, como ``SUM``, en los datos que queramos mostrar. Ver http://sqlfiddle.com/#!4/9b7433/4

```sql
    -- Este comando va a darnos error, porque GROUP BY muestra una fila por empresa,
    -- y al haber varios empleados por cada empresa no sabría qué nombre mostrar
    SELECT nombre FROM empleados GROUP BY empresa;

    -- Hay que usar una función de agregación:
    SELECT sum(sueldo) FROM empleados GROUP BY empresa;

    -- Podemos mostrar la columna del GROUP BY en el resultado del SELECT:
    SELECT sum(sueldo), empresa FROM empleados GROUP BY empresa;
```

## Joins

La cláusula ``JOIN`` se utiliza para enlazar datos que están distribuidos entre dos o más tablas pero comparten algún campo. Por ejemplo, si tenemos una tabla para empleados y otra con datos de empresas, podríamos hacer un join para obtener en una sola query toda la información de cada empleado y de la empresa en la que trabaja.

Ver la tabla de ejemplo para joins: http://sqlfiddle.com/#!4/4f1f5a/1.

La sintaxis del comando es ``SELECT columnas FROM tabla1 JOIN tabla2 ON columnasIguales``. ``columnas`` son las columnas que queremos que aparezcan en el resultado, y ``columnasIguales`` son las columnas cuyos contenidos deben coincidir.

```sql
    -- Este comando muestra en una sola fila la información de cada empleado 
    -- y toda la información del departamento al que pertenece
    SELECT * FROM empleados JOIN departamentos ON
    empleados.cod_dept = departamentos.cod_dept;

    -- Idéntico al anterior, pero sólo muestra empleados en el departamento 1
    SELECT * FROM empleados JOIN departamentos ON
    empleados.cod_dept = departamentos.cod_dept
    WHERE departamentos.cod_dept = 1;

    -- Siempre que hacemos ``SELECT *`` en un join vamos a tener columnas repetidas.
    -- Podemos elegir manualmente qué columnas queremos mostrar
    SELECT empleados.nombre, empleados.apellidos, departamentos.nombre
    FROM empleados JOIN departamentos ON
    empleados.cod_dept = departamentos.cod_dept;

    -- Podemos hacer varios joins en una sola consulta
    SELECT * FROM empleados JOIN e_bonos ON
    empleados.dni = e_bonos.dni JOIN bonos ON
    e_bonos.cod_bono = bonos.cod_bono;
```
Cualquier join se puede declarar de forma equivalente con un simple ``WHERE``. En general es preferible utilizar joins, porque son más legibles y más fáciles de optimizar.

```sql
SELECT suppliers.supplier_id, suppliers.supplier_name, orders.order_date
FROM suppliers, orders
WHERE suppliers.supplier_id = orders.supplier_id;

-- es equivalente a:

SELECT suppliers.supplier_id, suppliers.supplier_name, orders.order_date
FROM suppliers
JOIN orders
ON suppliers.supplier_id = orders.supplier_id;
```

##### Tipos de joins

Hay cuatro tipos de joins:

* ``INNER JOIN``: muestra sólo los elementos en los que la condición de unión se cumple.
* ``FULL JOIN``: muestra todas las columnas de todas las tablas, aunque la condición de unión no se cumpla.
* ``LEFT JOIN``: muestra todas las columnas de la tabla izquierda, y sólo las de la tabla derecha que cumplen la condición de unión.
* ``RIGHT JOIN``: muestra todas las columnas de la tabla derecha, y sólo las de la tabla izquierda que cumplen la condición de unión.

El join por defecto es ``INNER JOIN``. En los otros tres tipos (outer joins), cuando la condición no se cumple para una fila, esa fila se completa con ``null``.

## Funciones

Por ahora sólo hemos visto **funciones de agregación**, que toman como argumento un conjunto de filas y devuelven un solo valor. Estas funciones se utilizan dentro de un ``SELECT``, y se pueden combinar con todas las cláusulas de un ``SELECT``, como ``WHERE``, ``GROUP BY``, etc.

* ``SUM()``: calcula la suma de los valores, que deben ser números
* ``MAX()``, ``MIN()``: devuelve el máximo o mínimo de los valores
* ``AVG()``: calcula la media de los valores
* ``COUNT()``: devuelve el número de filas en una tabla. ``COUNT(*)`` devuelve el número total de filas, ``COUNT(ALL columna)`` devuelve todas las filas excepto si su valor en ``columna`` es ``null``, y ``COUNT(DISTINCT columna)`` devuelve el número de valores únicos en ``columna``, ignorando también los ``null``

    -- Obtiene la suma de los sueldos de los empleados de Amazon
    SELECT SUM(sueldo) FROM empleados WHERE empresa = 'Amazon';

    -- Cuenta el número total de empleados
    SELECT COUNT(*) FROM empleados;

    -- Cuenta el número de empresas que pagan más de 5000 euros a algún empleado
    SELECT COUNT(DISTINCT empresa) FROM empleados WHERE sueldo >= 5000;

Tener en cuenta que no podemos hacer una query que contenga, por ejemplo, ``nombre`` y ``sum(sueldo)``, porque el número de resultados sería diferente (``sum`` devuelve un solo resultado, y ``nombre`` devuelve uno por fila). Una forma de solucionar esto es utilizar ``GROUP BY``, ya que ``GROUP BY`` fuerza a la query a devolver un número fijo de resultados (uno por grupo).

```sql
    SELECT departamentos.descripcion, SUM(empleados.sueldo)
    FROM departamentos, empleados WHERE departamentos.cod_dept = empleados.cod_dept
    GROUP BY departamentos.descripcion;
```

Hay también [otros tipos de funciones](https://docs.oracle.com/cd/B19306_01/server.102/b14200/functions001.htm). Además, las bases de datos de Oracle incluyen un lenguaje de programación propio para complementar a SQL, llamado PL.
