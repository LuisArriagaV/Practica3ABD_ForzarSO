# Práctica 3: BancoTech - Auditoría y Stress Testing

## 📋 Información

**Duración:** 3-4 horas  
**Nivel:** Intermedio-Avanzado

## 🎯 Objetivos

1. Auditar un sistema bancario con **grandes volúmenes** de datos
2. Identificar vulnerabilidades de **seguridad** y **performance**
3. Detectar **race conditions** en transacciones concurrentes
4. Proponer y aplicar **correcciones**

## 🚀 Configuración

### Paso 1: Crear la Base de Datos

```bash
cd Practica3_ForzarSO
psql -U postgres -f setup_bancotech_db.sql
```

### Paso 2: Ejecutar la Aplicación

```bash
cd webapp
python3 app.py
```

Visita: http://localhost:5002

### Paso 3: Explorar el Sistema

**Credenciales de cliente:**
- Usuario: `user1` / Contraseña: `password1`
- Usuario: `user100` / Contraseña: `password100`

**Credenciales de admin:**
- Usuario: `admin` / Contraseña: `admin123`

---

## 📝 PARTE 1: EXPLORACIÓN DEL SISTEMA

### Ejercicio 1.1: Explorar como Cliente

1. Login como cliente (`user1` / `password1`)
2. Explora el dashboard
3. Ve tus cuentas y saldos
4. Revisa el historial de transacciones
5. Ve tus tarjetas

**Documenta:**
```
¿Qué información ves en el dashboard?


¿Cuántas cuentas tienes?


¿Qué datos de las tarjetas son visibles?


```

### Ejercicio 1.2: Realizar Transferencia

1. Ve a "Transferir"
2. Realiza una transferencia de $100 a la cuenta `10000000000002`
3. Verifica que se completó

**Documenta:**
```
¿Qué validaciones hace el sistema?


¿Qué pasa si transfieres más de tu saldo?


```

### Ejercicio 1.3: Explorar como Admin

1. Cierra sesión
2. Login como admin (`admin` / `admin123`)
3. Explora el panel de administración
4. Ve "Gestión de Clientes"
5. Ve "Transacciones"

**Documenta:**
```
¿Qué información sensible ves en "Gestión de Clientes"?


¿Qué datos de las transacciones son visibles?


```

---

## 🔍 PARTE 2: AUDITORÍA DE SEGURIDAD

### Ejercicio 2.1: Auditar Credenciales

Conéctate a la base de datos:
```bash
psql -U bancotech_app -d bancotech_db
```
Contraseña: `banco123`

**Investiga:**
```sql
-- Ver cómo se almacenan las contraseñas
SELECT username, password, pin FROM credenciales LIMIT 5;
```

**Documenta:**
```
HALLAZGO #1: Contraseñas
¿Cómo se almacenan?:


Riesgo:


Severidad (Baja/Media/Alta/Crítica):


```

### Ejercicio 2.2: Auditar Datos de Tarjetas

```sql
-- Ver datos de tarjetas
SELECT numero_tarjeta, cvv, fecha_expiracion FROM tarjetas LIMIT 5;
```

**Documenta:**
```
HALLAZGO #2: Tarjetas
¿Qué datos están expuestos?:


¿Cumple con PCI-DSS?:


Riesgo:


```

### Ejercicio 2.3: Auditar Permisos

```sql
-- Ver privilegios del usuario de la aplicación
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'bancotech_app'
ORDER BY table_name;
```

**Documenta:**
```
HALLAZGO #3: Privilegios
¿Qué permisos tiene bancotech_app?:


¿Son excesivos?:


¿Qué tablas NO debería poder ver?:


```

---

## ⚡ PARTE 3: ANÁLISIS DE PERFORMANCE

### Ejercicio 3.1: Identificar Queries Lentas

```sql
-- Buscar transacciones sin índice
EXPLAIN ANALYZE
SELECT * FROM transacciones 
WHERE cuenta_origen_id = 100;
```

**Documenta:**
```
Tipo de scan:


Tiempo de ejecución:


Filas escaneadas:


¿Es eficiente?:


```

### Ejercicio 3.2: Detectar Falta de Índices

```sql
-- Ver índices existentes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Documenta:**
```
Tablas sin índices en foreign keys:


Impacto en performance:


```

---

## 🏁 PARTE 4: RACE CONDITIONS

### Ejercicio 4.1: Probar Transferencia Concurrente

**Abrir 2 terminales y ejecutar simultáneamente:**

Terminal 1:
```sql
SELECT transferir_fondos(1, 2, 1000);
```

Terminal 2 (ejecutar inmediatamente):
```sql
SELECT transferir_fondos(1, 3, 1000);
```

**Documenta:**
```
¿Qué pasó con el saldo?:


¿Se permitieron ambas transferencias?:


¿Por qué ocurre esto?:


```

---

## 🛠️ PARTE 5: PROPONER CORRECCIONES

Para cada vulnerabilidad, propón una solución:

### Corrección #1: Contraseñas

```
Vulnerabilidad: Contraseñas en texto plano

Solución propuesta:


Consulta SQL para implementar:




```

### Corrección #2: Datos de Tarjetas

```
Vulnerabilidad: Tarjetas sin encriptar

Solución propuesta:


Consulta SQL para implementar:




```

### Corrección #3: Performance

```
Problema: Queries lentas

Solución propuesta:


Consulta SQL para implementar:




```

---

## 📊 PARTE 6: REPORTE FINAL

Crea un reporte que incluya:

1. **Resumen Ejecutivo** (1 página)
   - Vulnerabilidades críticas encontradas
   - Problemas de performance
   - Recomendaciones principales

2. **Hallazgos Detallados** (2-3 páginas)
   - Cada vulnerabilidad con evidencia
   - Capturas de pantalla
   - Impacto

3. **Correcciones Propuestas** (1-2 páginas)
   - Soluciones técnicas
   - Consultas SQL
   - Verificación

---

## ✅ Entrega

**Archivos:**
1. Reporte en PDF
2. Capturas de pantalla
3. Archivo `correcciones.sql` con tus soluciones

**Fecha:** _______________  
**Nombre:** _______________

---

## 💡 Consejos

- Usa `EXPLAIN ANALYZE` para analizar performance
- Documenta TODO con capturas
- Piensa en el impacto real de cada vulnerabilidad
- Las race conditions son difíciles de detectar - sé paciente

---

> [!TIP]
> Este sistema maneja 50,000 transacciones. Úsalo para probar cómo se comporta la BD bajo carga.
