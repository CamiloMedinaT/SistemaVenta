<?php
// app/controllers/AuthController.php
// MIGRACIÓN EXACTA de tu login.php actual

class AuthController {
    private $db;
    
    public function __construct() {
        // Inicializar conexión (igual que tu conexion.php pero en MVC)
        require_once '../app/core/Database.php';
        $this->db = Database::getConnection();
        
        // Iniciar sesión (como haces en tu login actual)
        //session_start();
        
        // Si YA está logueado, redirigir AL SISTEMA VIEJO (por ahora)
       // if(!empty($_SESSION['active'])) {
         //   header('location: ../sistema/');
         //   exit();
       // }
    }
    
    /**
     * Muestra el formulario de login (IGUAL a tu HTML actual)
     * URL: http://localhost/SistemaVenta/public/index.php?url=auth/login
     */
    public function login() {
        // Variable para mensajes de alerta (EXACTO como tu código)
        $alert = isset($_SESSION['alert']) ? $_SESSION['alert'] : '';
        unset($_SESSION['alert']); // Limpiar después de mostrar
        
        // Incluir la vista con el HTML IDÉNTICO al tuyo
        require_once '../views/auth/login.php';
    }
    
    /**
     * Procesa el formulario de login (MIGRACIÓN EXACTA de tu lógica)
     * URL: Se llama desde el formulario (POST)
     */
    public function procesarLogin() {
        // 1. Verificar que sea POST (como tu !empty($_POST))
        if($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $_SESSION['alert'] = 'Método no permitido';
            $this->redirect('auth/login');
            return;
        }
        
        // 2. Validar campos no vacíos (EXACTO a tu código)
        if(empty($_POST['usuario']) || empty($_POST['clave'])) {
            $_SESSION['alert'] = 'No has ingresado datos completos';
            $this->redirect('auth/login');
            return;
        }
        
        // 3. Limpiar inputs (MEJORADO pero conserva tu lógica)
        $user = $this->limpiarInput($_POST['usuario']);
        $pass = md5($this->limpiarInput($_POST['clave'])); // MD5 como usas
        
        // 4. CONSULTA SQL (EXACTA a la tuya pero con prepared statements)
        $query = "SELECT u.idusuario, u.nombre, u.correo, u.usuario, r.idrol, r.rol 
                 FROM usuario u 
                 INNER JOIN rol r ON u.rol = r.idrol
                 WHERE usuario = ? AND clave = ? AND u.status = 1";
        
        $stmt = $this->db->prepare($query);
        $stmt->bind_param("ss", $user, $pass);
        $stmt->execute();
        $result = $stmt->get_result();
        
        // 5. Verificar si encontró usuario (IGUAL a tu código)
        if($result->num_rows > 0) {
            $data = $result->fetch_assoc();
            
            // 6. CREAR SESIÓN (EXACTO a tus variables de sesión)
            $_SESSION['active'] = true;
            $_SESSION['idUser'] = $data['idusuario'];
            $_SESSION['nombre'] = $data['nombre'];
            $_SESSION['email'] = $data['correo'];
            $_SESSION['user'] = $data['usuario'];
            $_SESSION['rol'] = $data['idrol'];
            $_SESSION['rol_name'] = $data['rol'];
            
            // 7. Redirigir al SISTEMA VIEJO (por ahora)
// Por AHORA redirige al sistema viejo pero a nueva_venta.php
// En AuthController.php, línea 58:
header('Location: ../public/index.php?url=ventas/listar');
exit();

// MAÑANA cuando creemos HomeController:
// header('location: ../public/index.php?url=ventas/nueva');
// exit();
        } else {
            // 8. Credenciales incorrectas (IGUAL a tu lógica)
            $_SESSION['alert'] = 'El Usuario o contraseña son incorrectos';
            session_destroy(); // Como haces en tu código
            
            $this->redirect('auth/login');
        }
    }
    
    /**
     * Cierra sesión (nueva funcionalidad que puedes agregar después)
     */
    public function logout() {
        session_destroy();
        $this->redirect('auth/login');
    }
    
    /**
     * Redirige manteniendo la estructura de URLs MVC
     */
    private function redirect($url) {
        header('location: ../sistema/nueva_venta.php');
        exit();
    }
    
    /**
     * Limpia inputs (MEJORADO para seguridad)
     */
    private function limpiarInput($input) {
        $input = trim($input);
        $input = stripslashes($input);
        $input = htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
        return $input;
    }
}
?>