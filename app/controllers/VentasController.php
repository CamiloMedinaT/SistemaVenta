<?php
/**
 * VentasController.php
 * Controlador principal del módulo de ventas
 * Responsabilidad: Orquestar la lógica de ventas
 */

class VentasController {
    private $db;
    private $ventaModel;
    
    /**
     * Constructor: Verifica sesión y prepara recursos
     */
    public function __construct() {
        // 1. VERIFICAR SESIÓN ACTIVA - Seguridad primaria
       // session_start();
        if (empty($_SESSION['active']) || $_SESSION['active'] !== true) {
            $this->redirect('auth/login');
            return;
        }
        
        // 2. CARGAR CONEXIÓN A BD
        require_once '../app/core/Database.php';
        $this->db = Database::getConnection();
        
        // 3. CARGAR MODELO DE VENTAS (lo crearemos después)
        require_once '../app/models/VentaModel.php';
        $this->ventaModel = new VentaModel($this->db);
        
        // 4. CARGAR HELPER SI EXISTE (para cálculos, formatos, etc.)
        // require_once '../app/helpers/VentasHelper.php';
    }
    
    /**
     * Muestra la página principal de ventas
     * URL: http://localhost/SistemaVenta/public/index.php?url=ventas/nueva
     */
    public function nueva() {
        // 1. OBTENER DATOS NECESARIOS PARA LA VISTA
        $data = [
            'titulo' => 'Nueva Venta - Sistema POS',
            'usuario' => $_SESSION['nombre'] ?? 'Usuario',
            'productos' => $this->ventaModel->obtenerProductosActivos(),
            'clientes' => $this->ventaModel->obtenerClientesActivos(),
            'ultima_venta' => $this->ventaModel->obtenerUltimoNumeroVenta()
        ];
        
        // 2. CARGAR LA VISTA PRINCIPAL
        $this->cargarVista('modules/ventas/nueva_venta', $data);
    }
    
    /**
     * Procesa una nueva venta (POST desde formulario)
     * URL: Se llama desde el formulario de venta
     */
    public function procesarVenta() {
        // 1. VERIFICAR MÉTODO POST
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $_SESSION['error'] = 'Método no permitido';
            $this->redirect('ventas/nueva');
            return;
        }
        
        // 2. VALIDAR DATOS BÁSICOS
        if (empty($_POST['cliente_id']) || empty($_POST['productos'])) {
            $_SESSION['error'] = 'Datos incompletos para la venta';
            $this->redirect('ventas/nueva');
            return;
        }
        
        try {
            // 3. PROCESAR VENTA EN TRANSACCIÓN
            $resultado = $this->ventaModel->crearVenta([
                'cliente_id' => $_POST['cliente_id'],
                'usuario_id' => $_SESSION['idUser'],
                'productos' => json_decode($_POST['productos'], true),
                'total' => $_POST['total'],
                'descuento' => $_POST['descuento'] ?? 0,
                'observaciones' => $_POST['observaciones'] ?? ''
            ]);
            
            // 4. REDIRIGIR CON MENSAJE DE ÉXITO
            $_SESSION['success'] = '✅ Venta registrada exitosamente. N° ' . $resultado['numero_venta'];
            $this->redirect('ventas/nueva');
            
        } catch (Exception $e) {
            // 5. MANEJAR ERRORES
            $_SESSION['error'] = 'Error al procesar venta: ' . $e->getMessage();
            $this->redirect('ventas/nueva');
        }
    }
    
    /**
     * Muestra listado de ventas
     * URL: http://localhost/SistemaVenta/public/index.php?url=ventas/listar
     */
    public function listar() {
        // 1. OBTENER PARÁMETROS DE BÚSQUEDA
        $filtros = [
            'fecha_desde' => $_GET['fecha_desde'] ?? date('Y-m-01'),
            'fecha_hasta' => $_GET['fecha_hasta'] ?? date('Y-m-d'),
            'cliente_id' => $_GET['cliente_id'] ?? null,
            'estado' => $_GET['estado'] ?? 'completada'
        ];
        
        // 2. OBTENER VENTAS FILTRADAS
        $data = [
            'titulo' => 'Historial de Ventas',
            'ventas' => $this->ventaModel->obtenerVentas($filtros),
            'filtros' => $filtros,
            'total_ventas' => $this->ventaModel->obtenerTotalVentas($filtros)
        ];
        
        // 3. CARGAR VISTA
        $this->cargarVista('modules/ventas/listar', $data);
    }
    
    /**
     * Obtiene productos para búsqueda en tiempo real (AJAX)
     * URL: http://localhost/SistemaVenta/public/index.php?url=ventas/buscarProductos
     */
    public function buscarProductos() {
        // Solo respuesta JSON para AJAX
        header('Content-Type: application/json');
        
        $busqueda = $_GET['q'] ?? '';
        $productos = $this->ventaModel->buscarProductos($busqueda);
        
        echo json_encode($productos);
        exit();
    }
    
    /**
     * Carga una vista con datos
     * @param string $vista Nombre de la vista (sin .php)
     * @param array $datos Variables para la vista
     */
   private function cargarVista($vista, $datos = []) {
    // Extraer variables para la vista
    extract($datos);
    
    // Ruta CORREGIDA - Agrega 'auth/' 
    $rutaVista = '../views/auth/' . $vista . '.php';
    
    if (file_exists($rutaVista)) {
        require_once $rutaVista;
    } else {
        die("❌ Error: Vista no encontrada - $vista");
    }
}
    /**
     * Redirige a una URL dentro del MVC
     * @param string $url URL relativa (ej: 'ventas/nueva')
     */
    private function redirect($url) {
        header("Location: ../public/index.php?url=" . $url);
        exit();
    }
}
?>