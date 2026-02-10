<?php
/**
 * listar.php
 * Vista para listar ventas - Migración exacta de ventas.php
 * Responsabilidad: Solo mostrar HTML, la lógica está en el controlador
 */

// NOTA: NO incluyas session_start() ni conexion.php aquí
// Eso lo hace el controlador
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- INCLUIR SCRIPTS GENERALES (igual que tu includes/scripts.php) -->
    <?php 
    // Ruta ABSOLUTA para que funcione desde cualquier ubicación
    $base_url = '/SistemaVenta/';
    ?>
    <link rel="stylesheet" href="<?php echo $base_url; ?>css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <!-- CSS ESPECÍFICO para módulo ventas -->
    <link rel="stylesheet" href="<?php echo $base_url; ?>public/assets/css/ventas.css">
    
    <title>Lista de ventas - Sistema POS</title>
    
    <style>
        /* ESTILOS TEMPORALES (migraremos a ventas.css después) */
        .btn_new { background: #3a7; }
        .btn_view { background: #46a; }
        .form_search_date { margin: 15px 0; }
    </style>
</head>
<body>
    <!-- HEADER (igual que tu includes/header.php) -->
    <header>
        <div class="header-container">
            <div class="logo">
                <h1><i class="fas fa-store"></i> Sistema POS</h1>
            </div>
            <div class="user-info">
                <span><i class="fas fa-user"></i> <?php echo htmlspecialchars($usuario); ?></span>
                <a href="<?php echo $base_url; ?>public/index.php?url=auth/logout" class="logout">
                    <i class="fas fa-sign-out-alt"></i> Salir
                </a>
            </div>
        </div>
    </header>

    <section id="container">
        <!-- TÍTULO Y BOTÓN NUEVA VENTA -->
        <div class="header-ventas">
            <h1><i class="far fa-newspaper"></i> Lista de ventas</h1>
            <a href="<?php echo $base_url; ?>public/index.php?url=ventas/nueva" class="btn_new btnNewVenta">
                <i class="fas fa-plus"></i> Nueva venta
            </a>
        </div>

        <!-- BÚSQUEDA RÁPIDA -->
        <form action="" method="get" class="form_search" id="formBusqueda">
            <input type="hidden" name="url" value="ventas/listar">
            <input type="text" name="busqueda" id="busquedaVentas" 
                   placeholder="Buscar por cliente, número o vendedor..."
                   value="<?php echo htmlspecialchars($_GET['busqueda'] ?? ''); ?>">
            <button type="submit" class="btn_view">
                <i class="fas fa-search"></i> Buscar
            </button>
        </form>

        <!-- FILTROS POR FECHA -->
        <div class="filtros-container">
            <h5><i class="far fa-calendar-alt"></i> Buscar por fecha</h5>
            <form action="" method="get" class="form_search_date" id="formFechas">
                <input type="hidden" name="url" value="ventas/listar">
                
                <div class="filtro-group">
                    <label>De:</label>
                    <input type="date" name="fecha_desde" id="fecha_de" 
                           value="<?php echo $filtros['fecha_desde']; ?>" required>
                </div>
                
                <div class="filtro-group">
                    <label>A:</label>
                    <input type="date" name="fecha_hasta" id="fecha_a" 
                           value="<?php echo $filtros['fecha_hasta']; ?>" required>
                </div>
                
                <button type="submit" class="btn_view">
                    <i class="fas fa-search"></i> Filtrar
                </button>
                
                <!-- BOTONES ADICIONALES -->
                <a href="#" class="btn_view" id="reporte_pdf" onclick="generarPDF()">
                    <i class="fas fa-file-pdf"></i> Generar PDF
                </a>
                
                <?php if ($_SESSION['rol'] == 1): // Solo administradores ?>
                <a href="#" class="btn_new" id="devolucion" onclick="mostrarDevolucion()">
                    <i class="fas fa-undo-alt"></i> Devolución
                </a>
                <?php endif; ?>
            </form>
        </div>

        <!-- SELECTOR DE CANTIDAD A MOSTRAR -->
        <div class="mostrar-container">
            <p>
                <strong><i class="fas fa-list-ol"></i> Mostrar:</strong>
                <select name="limite" id="cantidad_mostrar_ventas" onchange="cambiarLimite(this.value)">
                    <option value="10" <?php echo ($limite ?? 10) == 10 ? 'selected' : ''; ?>>10</option>
                    <option value="25" <?php echo ($limite ?? 10) == 25 ? 'selected' : ''; ?>>25</option>
                    <option value="50" <?php echo ($limite ?? 10) == 50 ? 'selected' : ''; ?>>50</option>
                    <option value="100" <?php echo ($limite ?? 10) == 100 ? 'selected' : ''; ?>>100</option>
                </select> registros
            </p>
            
            <!-- TOTALES CORREGIDOS -->
            <div class="totales">
                <span class="total-ventas">
                    <strong>Total ventas:</strong> 
                    $<?php echo number_format($total_ventas ?? 0, 2); ?>
                </span>
                <span class="total-registros">
                    <strong>Registros:</strong> 
                    <?php 
                    // Verificar si $ventas es un array antes de contar
                    if (is_array($ventas)) {
                        echo count($ventas);
                    } else {
                        // Si no es array (podría ser 0, null, etc.)
                        echo 0;
                    }
                    ?>
                </span>
            </div>
        </div>

        <!-- TABLA DE VENTAS - CORREGIDO EL EMPTY() -->
        <div class="containerTable">
            <?php if (empty($ventas) || !is_array($ventas)): ?>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> No se encontraron ventas en el período seleccionado.
                </div>
            <?php else: ?>
                <table class="table-ventas">
                    <thead>
                        <tr>
                            <th>N° Venta</th>
                            <th>Fecha</th>
                            <th>Cliente</th>
                            <th>Vendedor</th>
                            <th>Total</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($ventas as $venta): ?>
                        <tr>
                            <td>#<?php echo str_pad($venta['noventa'], 6, '0', STR_PAD_LEFT); ?></td>
                            <td><?php echo date('d/m/Y H:i', strtotime($venta['fecha'])); ?></td>
                            <td><?php echo htmlspecialchars($venta['cliente'] ?? 'Cliente general'); ?></td>
                            <td><?php echo htmlspecialchars($venta['vendedor'] ?? 'Sistema'); ?></td>
                            <td class="text-right">$<?php echo number_format($venta['totalventa'], 2); ?></td>
                            <td>
                                <span class="estado estado-<?php echo strtolower($venta['estado'] ?? 'completada'); ?>">
                                    <?php echo ucfirst($venta['estado'] ?? 'Completada'); ?>
                                </span>
                            </td>
                            <td class="acciones">
                                <a href="<?php echo $base_url; ?>public/index.php?url=ventas/detalle/<?php echo $venta['noventa']; ?>" 
                                   class="btn_view" title="Ver detalle">
                                    <i class="far fa-eye"></i>
                                </a>
                                
                                <?php if ($venta['estado'] == 'completada' && $_SESSION['rol'] == 1): ?>
                                <a href="#" class="btn_edit" title="Anular venta" 
                                   onclick="anularVenta(<?php echo $venta['noventa']; ?>)">
                                    <i class="fas fa-ban"></i>
                                </a>
                                <?php endif; ?>
                                
                                <a href="<?php echo $base_url; ?>sistema/factura.php?id=<?php echo $venta['noventa']; ?>" 
                                   target="_blank" class="btn_pdf" title="Generar factura PDF">
                                    <i class="fas fa-file-invoice-dollar"></i>
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
        </div>

        <!-- PAGINACIÓN - CORREGIDO EL COUNT() -->
        <?php 
        // Calcular registros de forma segura
        $registros_count = 0;
        if (is_array($ventas)) {
            $registros_count = count($ventas);
        }
        $total_registros = $total_registros ?? $registros_count;
        
        if ($registros_count > 0 && $total_registros > ($limite ?? 10)): 
        ?>
        <div class="paginador" id="paginadorVentas">
            <nav>
                <?php
                $pagina_actual = $_GET['pagina'] ?? 1;
                $total_paginas = ceil($total_registros / ($limite ?? 10));
                
                if ($pagina_actual > 1):
                ?>
                <a href="?url=ventas/listar&pagina=<?php echo $pagina_actual - 1; ?>&limite=<?php echo $limite ?? 10; ?>" 
                   class="pagina anterior">
                    <i class="fas fa-chevron-left"></i> Anterior
                </a>
                <?php endif; ?>

                <span class="info-pagina">
                    Página <?php echo $pagina_actual; ?> de <?php echo $total_paginas; ?>
                </span>

                <?php if ($pagina_actual < $total_paginas): ?>
                <a href="?url=ventas/listar&pagina=<?php echo $pagina_actual + 1; ?>&limite=<?php echo $limite ?? 10; ?>" 
                   class="pagina siguiente">
                    Siguiente <i class="fas fa-chevron-right"></i>
                </a>
                <?php endif; ?>
            </nav>
        </div>
        <?php endif; ?>
    </section>

    <!-- FOOTER (igual que tu includes/footer.php) -->
    <footer>
        <div class="footer-container">
            <p>Sistema de Ventas POS v2.0 &copy; <?php echo date('Y'); ?> | MVC Migration</p>
            <p class="debug-info">
                <small>Tiempo: <?php echo round(microtime(true) - $_SERVER["REQUEST_TIME_FLOAT"], 3); ?>s</small>
            </p>
        </div>
    </footer>

    <!-- JavaScript ESPECÍFICO para ventas -->
    <script src="<?php echo $base_url; ?>public/assets/js/ventas.js"></script>
    
    <script>
    // FUNCIONES ESPECÍFICAS DE LA VISTA
    function cambiarLimite(limite) {
        const url = new URL(window.location.href);
        url.searchParams.set('limite', limite);
        url.searchParams.set('pagina', 1);
        window.location.href = url.toString();
    }
    
    function generarPDF() {
        const fecha_de = document.getElementById('fecha_de').value;
        const fecha_a = document.getElementById('fecha_a').value;
        
        window.open('<?php echo $base_url; ?>sistema/reporte_ventas_pdf.php?fecha_de=' + fecha_de + '&fecha_a=' + fecha_a, '_blank');
    }
    
    function anularVenta(idVenta) {
        if (confirm('¿Está seguro de anular esta venta? Esta acción no se puede deshacer.')) {
            window.location.href = '<?php echo $base_url; ?>public/index.php?url=ventas/anular/' + idVenta;
        }
    }
    
    function mostrarDevolucion() {
        alert('Funcionalidad de devolución - En desarrollo');
        // Aquí irá el modal de devolución
    }
    
    // Cargar más ventas con AJAX (si mantienes tu sistema actual)
    document.getElementById('busquedaVentas').addEventListener('input', function(e) {
        // Tu lógica AJAX actual aquí
    });
    </script>
</body>
</html>