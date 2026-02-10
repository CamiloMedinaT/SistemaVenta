<?php
class Database {
    private static $connection = null;
    
    public static function getConnection() {
        if (self::$connection === null) {
            try {
                // Crear conexión usando Config.php
                self::$connection = new mysqli(
                    Config::DB_HOST,
                    Config::DB_USER,
                    Config::DB_PASS,
                    Config::DB_NAME
                );
                
                // Verificar errores
                if (self::$connection->connect_error) {
                    throw new Exception("MySQL: " . self::$connection->connect_error);
                }
                
                // Configurar para acentos y caracteres especiales
                self::$connection->set_charset("utf8mb4");
                
            } catch (Exception $e) {
                // Error amigable para usuario, detalle en logs
                error_log("Error BD: " . $e->getMessage());
                die("⚠️ Error conectando a la base de datos. Contacta al administrador.");
            }
        }
        
        return self::$connection;
    }
    
    public static function closeConnection() {
        if (self::$connection !== null) {
            self::$connection->close();
            self::$connection = null;
        }
    }
}
?>