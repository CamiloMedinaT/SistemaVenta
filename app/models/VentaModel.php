<?php
/**
 * VentaModel.php
 * Modelo para operaciones de base de datos relacionadas con ventas
 * Responsabilidad: Solo interactuar con la BD
 */

class VentaModel {
    private $db;
    
    public function __construct($conexion) {
        $this->db = $conexion;
    }
    
    /**
     * Obtiene productos activos para venta
     * @return array Lista de productos con stock > 0
     */
    public function obtenerProductosActivos() {
        $query = "SELECT codproducto, descripcion, precio, existencia 
                  FROM producto 
                  WHERE status = 1 AND existencia > 0
                  ORDER BY descripcion";
        
        $result = $this->db->query($query);
        $productos = [];
        
        while ($row = $result->fetch_assoc()) {
            $productos[] = $row;
        }
        
        return $productos;
    }
    
    /**
     * Obtiene clientes activos
     * @return array Lista de clientes
     */
    public function obtenerClientesActivos() {
        $query = "SELECT idcliente, nombre, nit 
                  FROM cliente 
                  WHERE status = 1
                  ORDER BY nombre";
        
        $result = $this->db->query($query);
        $clientes = [];
        
        while ($row = $result->fetch_assoc()) {
            $clientes[] = $row;
        }
        
        return $clientes;
    }
    
    /**
     * Obtiene el último número de venta
     * @return int Último número + 1
     */
    public function obtenerUltimoNumeroVenta() {
        $query = "SELECT MAX(noventa) as ultimo FROM venta";
        $result = $this->db->query($query);
        $row = $result->fetch_assoc();
        
        return ($row['ultimo'] ?? 0) + 1;
    }
    
    /**
     * Busca productos por término
     * @param string $busqueda Término de búsqueda
     * @return array Productos encontrados
     */
    public function buscarProductos($busqueda) {
        $busqueda = $this->db->real_escape_string($busqueda);
        
        $query = "SELECT codproducto, descripcion, precio, existencia 
                  FROM producto 
                  WHERE (descripcion LIKE '%$busqueda%' OR codigo LIKE '%$busqueda%')
                  AND status = 1 AND existencia > 0
                  LIMIT 10";
        
        $result = $this->db->query($query);
        $productos = [];
        
        while ($row = $result->fetch_assoc()) {
            $productos[] = [
                'id' => $row['codproducto'],
                'text' => $row['descripcion'] . ' - $' . $row['precio'] . ' (Stock: ' . $row['existencia'] . ')',
                'precio' => $row['precio'],
                'stock' => $row['existencia']
            ];
        }
        
        return $productos;
    }
    
    /**
     * Crea una nueva venta con transacción
     * @param array $datos Datos de la venta
     * @return array Resultado con número de venta
     * @throws Exception Si falla la transacción
     */
    public function crearVenta($datos) {
        // INICIAR TRANSACCIÓN
        $this->db->begin_transaction();
        
        try {
            // 1. INSERTAR VENTA PRINCIPAL
            $queryVenta = "INSERT INTO venta (usuario, codcliente, totalventa, descuento, fecha) 
                          VALUES (?, ?, ?, ?, NOW())";
            
            $stmtVenta = $this->db->prepare($queryVenta);
            $stmtVenta->bind_param("iidd", 
                $datos['usuario_id'],
                $datos['cliente_id'],
                $datos['total'],
                $datos['descuento']
            );
            
            if (!$stmtVenta->execute()) {
                throw new Exception("Error al crear venta: " . $stmtVenta->error);
            }
            
            $ventaId = $this->db->insert_id;
            
            // 2. INSERTAR DETALLES DE VENTA
            foreach ($datos['productos'] as $producto) {
                $queryDetalle = "INSERT INTO detalleventa (noventa, codproducto, cantidad, precio_venta) 
                                VALUES (?, ?, ?, ?)";
                
                $stmtDetalle = $this->db->prepare($queryDetalle);
                $stmtDetalle->bind_param("iiid",
                    $ventaId,
                    $producto['id'],
                    $producto['cantidad'],
                    $producto['precio']
                );
                
                if (!$stmtDetalle->execute()) {
                    throw new Exception("Error al crear detalle: " . $stmtDetalle->error);
                }
                
                // 3. ACTUALIZAR STOCK
                $queryStock = "UPDATE producto 
                              SET existencia = existencia - ? 
                              WHERE codproducto = ?";
                
                $stmtStock = $this->db->prepare($queryStock);
                $stmtStock->bind_param("ii",
                    $producto['cantidad'],
                    $producto['id']
                );
                
                if (!$stmtStock->execute()) {
                    throw new Exception("Error al actualizar stock: " . $stmtStock->error);
                }
            }
            
            // 4. CONFIRMAR TRANSACCIÓN
            $this->db->commit();
            
            return [
                'success' => true,
                'numero_venta' => $ventaId,
                'mensaje' => 'Venta registrada exitosamente'
            ];
            
        } catch (Exception $e) {
            // 5. REVERTIR EN CASO DE ERROR
            $this->db->rollback();
            throw $e;
        }
    }
    
    /**
     * Obtiene ventas con filtros
     * @param array $filtros Filtros de búsqueda
     * @return array Ventas encontradas
     */
    public function obtenerVentas($filtros) {
        $where = "WHERE v.fecha BETWEEN ? AND ?";
        $params = [$filtros['fecha_desde'], $filtros['fecha_hasta']];
        $types = "ss";
        
        if (!empty($filtros['cliente_id'])) {
            $where .= " AND v.codcliente = ?";
            $params[] = $filtros['cliente_id'];
            $types .= "i";
        }
        
        if (!empty($filtros['estado'])) {
            $where .= " AND v.status = ?";
            $params[] = $filtros['estado'];
            $types .= "s";
        }
        
        $query = "SELECT v.noventa, v.fecha, v.totalventa, c.nombre as cliente, u.nombre as vendedor
                  FROM venta v
                  LEFT JOIN cliente c ON v.codcliente = c.idcliente
                  LEFT JOIN usuario u ON v.usuario = u.idusuario
                  $where
                  ORDER BY v.fecha DESC
                  LIMIT 100";
        
        $stmt = $this->db->prepare($query);
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $ventas = [];
        while ($row = $result->fetch_assoc()) {
            $ventas[] = $row;
        }
        
        return $ventas;
    }
    
    /**
     * Obtiene total de ventas en período
     * @param array $filtros Filtros de búsqueda
     * @return float Total de ventas
     */
    public function obtenerTotalVentas($filtros) {
        $where = "WHERE fecha BETWEEN ? AND ? AND status = 'completada'";
        $params = [$filtros['fecha_desde'], $filtros['fecha_hasta']];
        
        if (!empty($filtros['cliente_id'])) {
            $where .= " AND codcliente = ?";
            $params[] = $filtros['cliente_id'];
        }
        
        $query = "SELECT SUM(totalventa) as total FROM venta $where";
        $stmt = $this->db->prepare($query);
        
        if (count($params) == 2) {
            $stmt->bind_param("ss", ...$params);
        } else {
            $stmt->bind_param("ssi", ...$params);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        
        return $row['total'] ?? 0;
    }
}
?>