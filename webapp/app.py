"""
BancoTech - Sistema Bancario en Línea
======================================
Aplicación web Flask para gestión bancaria.

ADVERTENCIA: Aplicación con vulnerabilidades intencionales
para fines educativos de auditoría y stress testing.
"""

from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
from functools import wraps
import threading
import time

app = Flask(__name__)
app.secret_key = 'bancotech_secret_123'  # VULNERABLE: clave débil

# Configuración de base de datos
DB_CONFIG = {
    'dbname': 'bancotech_db',
    'user': 'bancotech_app',
    'password': 'banco123',
    'host': 'localhost',
    'port': '5432'
}

def get_db_connection():
    """Obtener conexión a la base de datos"""
    conn = psycopg2.connect(**DB_CONFIG)
    return conn

def login_required(f):
    """Decorador para rutas que requieren autenticación"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Debes iniciar sesión primero', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorador para rutas de administrador"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'rol' not in session or session['rol'] != 'admin':
            flash('Acceso denegado', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

# ============================================================================
# RUTAS PÚBLICAS
# ============================================================================

@app.route('/')
def index():
    """Página principal"""
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login de clientes"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # VULNERABLE: Contraseña en texto plano
        cur.execute("""
            SELECT c.*, cr.username
            FROM clientes c
            JOIN credenciales cr ON c.id = cr.cliente_id
            WHERE cr.username = %s AND cr.password = %s
        """, (username, password))
        
        user = cur.fetchone()
        
        if user:
            session['user_id'] = user['id']
            session['nombre'] = user['nombre']
            session['tipo'] = 'cliente'
            flash(f'Bienvenido {user["nombre"]}!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Credenciales incorrectas', 'danger')
        
        cur.close()
        conn.close()
    
    return render_template('login.html')

@app.route('/login/admin', methods=['GET', 'POST'])
def login_admin():
    """Login de empleados"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # VULNERABLE: Contraseña en texto plano
        cur.execute("""
            SELECT e.*, ce.rol
            FROM empleados e
            JOIN credenciales_empleados ce ON e.id = ce.empleado_id
            WHERE ce.username = %s AND ce.password = %s
        """, (username, password))
        
        user = cur.fetchone()
        
        if user:
            session['user_id'] = user['id']
            session['nombre'] = user['nombre']
            session['tipo'] = 'empleado'
            session['rol'] = user['rol']
            flash(f'Bienvenido {user["nombre"]}!', 'success')
            return redirect(url_for('admin_dashboard'))
        else:
            flash('Credenciales incorrectas', 'danger')
        
        cur.close()
        conn.close()
    
    return render_template('login_admin.html')

@app.route('/logout')
def logout():
    """Cerrar sesión"""
    session.clear()
    flash('Sesión cerrada', 'info')
    return redirect(url_for('index'))

# ============================================================================
# DASHBOARD DE CLIENTE
# ============================================================================

@app.route('/dashboard')
@login_required
def dashboard():
    """Dashboard principal del cliente"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Obtener cuentas del cliente
    cur.execute("""
        SELECT * FROM cuentas 
        WHERE cliente_id = %s AND estado = 'Activa'
        ORDER BY tipo_cuenta
    """, (session['user_id'],))
    cuentas = cur.fetchall()
    
    # Obtener transacciones recientes
    cur.execute("""
        SELECT t.*, 
               co.numero_cuenta as cuenta_origen,
               cd.numero_cuenta as cuenta_destino
        FROM transacciones t
        LEFT JOIN cuentas co ON t.cuenta_origen_id = co.id
        LEFT JOIN cuentas cd ON t.cuenta_destino_id = cd.id
        WHERE co.cliente_id = %s OR cd.cliente_id = %s
        ORDER BY t.fecha DESC
        LIMIT 10
    """, (session['user_id'], session['user_id']))
    transacciones = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('dashboard.html', cuentas=cuentas, transacciones=transacciones)

@app.route('/transferir', methods=['GET', 'POST'])
@login_required
def transferir():
    """Realizar transferencia"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Obtener cuentas del cliente
    cur.execute("""
        SELECT * FROM cuentas 
        WHERE cliente_id = %s AND estado = 'Activa'
    """, (session['user_id'],))
    mis_cuentas = cur.fetchall()
    
    if request.method == 'POST':
        cuenta_origen_id = request.form.get('cuenta_origen')
        cuenta_destino_num = request.form.get('cuenta_destino')
        monto = float(request.form.get('monto'))
        descripcion = request.form.get('descripcion', '')
        
        # Buscar cuenta destino
        cur.execute("SELECT id FROM cuentas WHERE numero_cuenta = %s", (cuenta_destino_num,))
        cuenta_destino = cur.fetchone()
        
        if not cuenta_destino:
            flash('Cuenta destino no encontrada', 'danger')
        else:
            # VULNERABLE: Usar función con race condition
            cur.execute("""
                SELECT transferir_fondos(%s, %s, %s)
            """, (cuenta_origen_id, cuenta_destino['id'], monto))
            
            resultado = cur.fetchone()
            conn.commit()
            
            if resultado:
                flash(f'Transferencia de ${monto:.2f} realizada exitosamente', 'success')
                return redirect(url_for('dashboard'))
            else:
                flash('Saldo insuficiente', 'danger')
    
    cur.close()
    conn.close()
    
    return render_template('transferir.html', cuentas=mis_cuentas)

@app.route('/tarjetas')
@login_required
def tarjetas():
    """Ver tarjetas del cliente"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # VULNERABLE: Muestra datos completos de tarjetas
    cur.execute("""
        SELECT t.*, c.numero_cuenta, c.tipo_cuenta
        FROM tarjetas t
        JOIN cuentas c ON t.cuenta_id = c.id
        WHERE c.cliente_id = %s
    """, (session['user_id'],))
    tarjetas = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('tarjetas.html', tarjetas=tarjetas)

# ============================================================================
# PANEL DE ADMINISTRACIÓN
# ============================================================================

@app.route('/admin')
@login_required
@admin_required
def admin_dashboard():
    """Dashboard de administración"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Estadísticas
    cur.execute("SELECT COUNT(*) as total FROM clientes WHERE activo = TRUE")
    total_clientes = cur.fetchone()['total']
    
    cur.execute("SELECT COUNT(*) as total FROM cuentas WHERE estado = 'Activa'")
    total_cuentas = cur.fetchone()['total']
    
    cur.execute("SELECT SUM(saldo) as total FROM cuentas WHERE estado = 'Activa'")
    total_depositos = cur.fetchone()['total'] or 0
    
    cur.execute("""
        SELECT COUNT(*) as total FROM transacciones 
        WHERE DATE(fecha) = CURRENT_DATE
    """)
    transacciones_hoy = cur.fetchone()['total']
    
    # Transacciones recientes
    cur.execute("""
        SELECT t.*, 
               co.numero_cuenta as cuenta_origen,
               cd.numero_cuenta as cuenta_destino
        FROM transacciones t
        LEFT JOIN cuentas co ON t.cuenta_origen_id = co.id
        LEFT JOIN cuentas cd ON t.cuenta_destino_id = cd.id
        ORDER BY t.fecha DESC
        LIMIT 20
    """)
    transacciones = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin/dashboard.html',
                         total_clientes=total_clientes,
                         total_cuentas=total_cuentas,
                         total_depositos=total_depositos,
                         transacciones_hoy=transacciones_hoy,
                         transacciones=transacciones)

@app.route('/admin/clientes')
@login_required
@admin_required
def admin_clientes():
    """Gestión de clientes"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # VULNERABLE: Muestra información sensible
    cur.execute("""
        SELECT c.*, cr.username, cr.password, cr.pin
        FROM clientes c
        LEFT JOIN credenciales cr ON c.id = cr.cliente_id
        ORDER BY c.id DESC
        LIMIT 100
    """)
    clientes = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin/clientes.html', clientes=clientes)

@app.route('/admin/transacciones')
@login_required
@admin_required
def admin_transacciones():
    """Ver todas las transacciones"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # VULNERABLE: Query sin paginación, puede ser muy lento
    cur.execute("""
        SELECT t.*, 
               co.numero_cuenta as cuenta_origen,
               cd.numero_cuenta as cuenta_destino,
               co.cliente_id as cliente_origen_id
        FROM transacciones t
        LEFT JOIN cuentas co ON t.cuenta_origen_id = co.id
        LEFT JOIN cuentas cd ON t.cuenta_destino_id = cd.id
        ORDER BY t.fecha DESC
        LIMIT 500
    """)
    transacciones = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin/transacciones.html', transacciones=transacciones)

# ============================================================================
# API (VULNERABLE)
# ============================================================================

@app.route('/api/saldo/<numero_cuenta>')
def api_saldo(numero_cuenta):
    """API para consultar saldo (VULNERABLE: sin autenticación)"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    cur.execute("""
        SELECT numero_cuenta, tipo_cuenta, saldo
        FROM cuentas
        WHERE numero_cuenta = %s
    """, (numero_cuenta,))
    cuenta = cur.fetchone()
    
    cur.close()
    conn.close()
    
    if cuenta:
        return jsonify(dict(cuenta))
    else:
        return jsonify({'error': 'Cuenta no encontrada'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5005)

