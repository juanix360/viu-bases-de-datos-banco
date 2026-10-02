# Sistema Bancario - Diseño e Implementación de Base de Datos

**Máster:** Big Data y Ciencia de Datos  
**Asignatura:** Herramientas de Bases de Datos (17MBID)  
**Universidad:** Universidad Internacional de Valencia (VIU)  
**Alumno:** Juan David Ortiz Encarnación  

---

## 📌 Contenido del Repositorio

Este repositorio contiene la solución completa a la actividad práctica del diseño e implementación del sistema bancario:

1. **`banco_sistema.sql`**: Script completo para **MySQL 8.0+** que incluye:
   - **DDL:** Creación de tablas, claves primarias, claves foráneas, restricciones `CHECK`, borrados en cascada y columna virtual generada para la antigüedad del empleado.
   - **DML:** Inserción de datos de prueba interconectados.
   - **DQL:** Consultas SELECT básicas y consultas avanzadas con el operador **`INTERSECT`** y `INNER JOIN`.
   - **CRUD:** Sentencias demostrativas completas (`INSERT`, `SELECT`, `UPDATE`, `DELETE`).

2. **`banco_sistema_pgadmin.sql`**: Versión adaptada y optimizada para **PostgreSQL 14+ / pgAdmin 4**, implementando tipos enumerados nativos (`ENUM`), vista para atributos derivados y sintaxis estándar.

3. **`Diagrama_Banco_ER.drawio`**: Archivo de diagramas para [diagrams.net (Draw.io)](https://app.diagrams.net/):
   - **Página 1:** Diagrama Entidad–Relación Conceptual detallado (notación Chen / académica).
   - **Página 2:** Diagrama Relacional normalizado en 3FN con claves conectadas.

---

## 🏛️ Modelo Entidad-Relación y Relacional

El modelo da cobertura a:
- **Sucursales:** Supervisión de activos y concesión de préstamos.
- **Clientes:** Asesor personal asignado y apertura de cuentas/préstamos.
- **Cuentas bancarias:** Especialización disjunta y total (*ISA*) en Cuentas de Ahorro y Cuentas Corrientes, con cotitularidad (N:M).
- **Préstamos:** Cotitularidad de clientes y entidad débil de **Pagos**.
- **Empleados:** Jerarquía reflexiva de jefes, cálculo de antigüedad y entidad débil de **Dependientes** (cumpliendo 1FN).
