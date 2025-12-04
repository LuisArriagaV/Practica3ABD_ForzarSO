# Práctica 3: BancoTech - Sistema Bancario para Stress Testing

## 📋 Información General

**Objetivo:** Auditar un sistema bancario en línea que maneja grandes volúmenes de datos y transacciones concurrentes.

**Características:**
- 5,000 clientes activos
- 7,000 cuentas bancarias
- 50,000 transacciones históricas
- Sistema de transferencias en tiempo real
- Gestión de tarjetas de crédito/débito

## 🚀 Instalación

### Paso 1: Crear la Base de Datos

```bash
cd Practica3_ForzarSO
psql -U postgres -f setup_bancotech_db.sql
```

Esto creará:
- Base de datos `bancotech_db`
- 8 tablas principales
- Datos de prueba masivos
- Usuarios de BD

### Paso 2: Ejecutar la Aplicación Web

```bash
cd webapp
python3 app.py
```

La aplicación estará disponible en: http://localhost:5002

## 🔑 Credenciales de Prueba

**Clientes:**
- Usuario: `user1` / Contraseña: `password1`
- Usuario: `user100` / Contraseña: `password100`
- Usuario: `user500` / Contraseña: `password500`

**Administradores:**
- Usuario: `admin` / Contraseña: `admin123`
- Usuario: `gerente` / Contraseña: `gerente2024`

## 🎯 Objetivos de la Práctica

1. **Auditar seguridad** del sistema bancario
2. **Identificar problemas de performance** con grandes volúmenes
3. **Detectar race conditions** en transferencias
4. **Proponer optimizaciones** para mejorar rendimiento
5. **Implementar correcciones** de seguridad

## ⚠️ Vulnerabilidades Implementadas

Esta aplicación incluye vulnerabilidades intencionales para fines educativos:

- Contraseñas y PINs en texto plano
- Datos de tarjetas sin encriptar (CVV visible)
- Race conditions en transferencias
- API sin autenticación
- Números de cuenta predecibles
- Queries sin índices (performance issues)
- Logs de transacciones sin protección

## 📊 Estructura de Archivos

```
Practica3_ForzarSO/
├── README.md                   # Este archivo
├── setup_bancotech_db.sql      # Script de base de datos
├── ESTUDIANTES.md              # Guía para estudiantes
├── README_PROFESOR_SIMPLE.md   # Guía para profesor
└── webapp/
    ├── app.py                  # Aplicación Flask
    ├── static/
    │   └── css/
    │       └── style.css
    └── templates/
        ├── base.html
        ├── index.html
        ├── login.html
        ├── dashboard.html
        ├── transferir.html
        ├── tarjetas.html
        └── admin/
            ├── dashboard.html
            ├── clientes.html
            └── transacciones.html
```

## 🔍 Características del Sistema

### Para Clientes:
- Ver saldos de cuentas
- Realizar transferencias
- Consultar historial de transacciones
- Ver tarjetas asociadas

### Para Administradores:
- Dashboard con estadísticas
- Gestión de clientes
- Visualización de todas las transacciones
- Reportes del sistema

## 🆘 Troubleshooting

**Error de conexión a BD:**
```bash
# Verificar que PostgreSQL esté corriendo
pg_ctl status

# Verificar usuario
psql -U bancotech_app -d bancotech_db
```

**Puerto 5002 en uso:**
```bash
# Cambiar puerto en app.py línea final
app.run(debug=True, host='0.0.0.0', port=5003)
```

## 📚 Siguiente Paso

Continúa con:
- [ESTUDIANTES.md](ESTUDIANTES.md) - Guía de auditoría
- [README_PROFESOR_SIMPLE.md](README_PROFESOR_SIMPLE.md) - Soluciones

---

> [!WARNING]
> Este sistema contiene vulnerabilidades intencionales. **NO** usar en producción.
