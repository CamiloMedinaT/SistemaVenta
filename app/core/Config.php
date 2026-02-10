<?php
class Config {
    // 1. DATABASE - Conexión MySQL (USA TUS DATOS EXACTOS)
    const DB_HOST = 'localhost';
    const DB_USER = 'root';
    const DB_PASS = '';       // Tu contraseña de XAMPP (normalmente vacía)
    const DB_NAME = 'bd_ventas'; // Tu base de datos exacta
    
    // 2. APPLICATION - Información general
    const APP_NAME = 'Sistema de Ventas POS';
    const APP_VERSION = '2.0';
    
    // 3. PATHS - Rutas fundamentales
    public static function base_url() {
        // Retorna: http://localhost/SistemaVenta/
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https://' : 'http://';
        $host = $_SERVER['HTTP_HOST'];
        $folder = dirname($_SERVER['SCRIPT_NAME']);
        return $protocol . $host . $folder . '/';
    }
    
    // 4. SESSION - Configuración segura
    const SESSION_TIMEOUT = 28800; // 8 horas
    const SESSION_NAME = 'POS_SESSION';
}
?>