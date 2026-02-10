<?php
class Router {
    private $controller = 'Auth';   // Controlador por defecto
    private $method = 'login';      // Método por defecto  
    private $params = [];           // Parámetros extras
    
    public function __construct() {
        $this->parseUrl();
        $this->dispatch();
    }
    
    private function parseUrl() {
        // Ejemplo: public/index.php?url=ventas/nueva/123
        // Se convierte en: controller=Ventas, method=nueva, params=[123]
        
        if (isset($_GET['url'])) {
            $url = rtrim($_GET['url'], '/');
            $url = filter_var($url, FILTER_SANITIZE_URL);
            $urlParts = explode('/', $url);
            
            if (!empty($urlParts[0])) {
                $this->controller = ucfirst($urlParts[0]);
            }
            
            if (!empty($urlParts[1])) {
                $this->method = $urlParts[1];
            }
            
            $this->params = array_slice($urlParts, 2);
        }
    }
    
    private function dispatch() {
        // 1. Construir ruta al controlador
        $controllerFile = '../app/controllers/' . $this->controller . 'Controller.php';
        
        // 2. Verificar si existe
        if (file_exists($controllerFile)) {
            require_once $controllerFile;
            $controllerClass = $this->controller . 'Controller';
            
            // 3. Crear instancia
            $controllerInstance = new $controllerClass();
            
            // 4. Verificar si el método existe
            if (method_exists($controllerInstance, $this->method)) {
                // 5. Ejecutar método con parámetros
                call_user_func_array(
                    [$controllerInstance, $this->method],
                    $this->params
                );
            } else {
                die("❌ Error 404: Método '{$this->method}' no encontrado.");
            }
        } else {
            die("❌ Error 404: Controlador '{$this->controller}' no encontrado.");
        }
    }
}
?>