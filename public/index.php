<?php
// 1. Configurar sesiones SEGURAS
session_start([
    'name' => 'POS_SESSION',
    'cookie_lifetime' => 28800, // 8 horas
    'cookie_secure' => false,    // TRUE cuando tengas HTTPS
    'cookie_httponly' => true,   // Previene acceso via JavaScript
    'use_strict_mode' => true    // Seguridad extra
]);

// 2. Cargar el núcleo del sistema MVC
require_once '../app/core/Config.php';
require_once '../app/core/Database.php';
require_once '../app/core/Router.php';

// 3. Iniciar el enrutador (él decide qué mostrar)
try {
    new Router();
} catch (Exception $e) {
    // Error amigable
    echo "<h2>⚠️ Error en la aplicación</h2>";
    echo "<p>Por favor, contacta al administrador.</p>";
    
    // Solo en desarrollo mostrar detalles
    if (in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'])) {
        echo "<pre>Error: " . $e->getMessage() . "</pre>";
    }
}
?>