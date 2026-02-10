/**
 * ventas.js
 * JavaScript específico para el módulo de ventas
 * Separado del JS general para mejor mantenimiento
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log('Módulo de ventas cargado - MVC v2.0');
    
    // INICIALIZAR COMPONENTES
    initFiltrosFecha();
    initBusquedaRapida();
    initTooltips();
    
    // CARGAR DATOS INICIALES SI ES NECESARIO
    if (document.getElementById('listaVentas').innerHTML.trim() === '') {
        cargarVentas();
    }
});

/**
 * Inicializa los filtros de fecha con valores por defecto
 */
function initFiltrosFecha() {
    const fechaDe = document.getElementById('fecha_de');
    const fechaA = document.getElementById('fecha_a');
    
    // Si no tienen valor, establecer por defecto (mes actual)
    if (!fechaDe.value) {
        const primerDiaMes = new Date();
        primerDiaMes.setDate(1);
        fechaDe.value = primerDiaMes.toISOString().split('T')[0];
    }
    
    if (!fechaA.value) {
        fechaA.value = new Date().toISOString().split('T')[0];
    }
    
    // Validar que fecha A no sea menor que fecha De
    fechaA.addEventListener('change', function() {
        if (fechaDe.value && this.value < fechaDe.value) {
            alert('La fecha "A" no puede ser menor que la fecha "De"');
            this.value = fechaDe.value;
        }
    });
    
    fechaDe.addEventListener('change', function() {
        if (fechaA.value && fechaA.value < this.value) {
            fechaA.value = this.value;
        }
    });
}

/**
 * Inicializa la búsqueda rápida con debounce
 */
function initBusquedaRapida() {
    const busquedaInput = document.getElementById('busquedaVentas');
    
    if (!busquedaInput) return;
    
    let timeoutId;
    
    busquedaInput.addEventListener('input', function(e) {
        clearTimeout(timeoutId);
        
        timeoutId = setTimeout(() => {
            const busqueda = e.target.value.trim();
            
            if (busqueda.length >= 2 || busqueda.length === 0) {
                buscarVentas(busqueda);
            }
        }, 500); // Debounce de 500ms
    });
}

/**
 * Busca ventas mediante AJAX
 * @param {string} busqueda - Término de búsqueda
 */
function buscarVentas(busqueda) {
    const filtros = obtenerFiltrosActuales();
    filtros.busqueda = busqueda;
    
    // Mostrar loading
    const container = document.getElementById('listaVentas');
    container.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i> Buscando...</div>';
    
    // Llamada AJAX al controlador MVC
    fetch(`/SistemaVenta/public/index.php?url=ventas/buscarAjax`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(filtros)
    })
    .then(response => response.json())
    .then(data => {
        actualizarTablaVentas(data.ventas);
        actualizarPaginador(data.paginacion);
    })
    .catch(error => {
        console.error('Error en búsqueda:', error);
        container.innerHTML = '<div class="alert alert-danger">Error al cargar ventas</div>';
    });
}

/**
 * Carga ventas con los filtros actuales
 */
function cargarVentas() {
    const filtros = obtenerFiltrosActuales();
    buscarVentas(filtros.busqueda || '');
}

/**
 * Obtiene los filtros actuales del formulario
 * @returns {Object} Filtros actuales
 */
function obtenerFiltrosActuales() {
    return {
        fecha_desde: document.getElementById('fecha_de').value,
        fecha_hasta: document.getElementById('fecha_a').value,
        busqueda: document.getElementById('busquedaVentas').value,
        limite: document.getElementById('cantidad_mostrar_ventas').value,
        pagina: new URLSearchParams(window.location.search).get('pagina') || 1
    };
}

/**
 * Actualiza la tabla de ventas con nuevos datos
 * @param {Array} ventas - Lista de ventas
 */
function actualizarTablaVentas(ventas) {
    const container = document.getElementById('listaVentas');
    
    if (!ventas || ventas.length === 0) {
        container.innerHTML = '<div class="alert alert-info">No se encontraron ventas</div>';
        return;
    }
    
    let html = `
        <table class="table-ventas">
            <thead>
                <tr>
                    <th>N° Venta</th>
                    <th>Fecha</th>
                    <th>Cliente</th>
                    <th>Total</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>`;
    
    ventas.forEach(venta => {
        html += `
            <tr>
                <td>#${String(venta.noventa).padStart(6, '0')}</td>
                <td>${formatFecha(venta.fecha)}</td>
                <td>${escapeHtml(venta.cliente || 'Cliente general')}</td>
                <td class="text-right">$${formatMoneda(venta.totalventa)}</td>
                <td>
                    <span class="estado estado-${venta.estado?.toLowerCase() || 'completada'}">
                        ${venta.estado ? venta.estado.charAt(0).toUpperCase() + venta.estado.slice(1) : 'Completada'}
                    </span>
                </td>
                <td class="acciones">
                    <a href="/SistemaVenta/public/index.php?url=ventas/detalle/${venta.noventa}" 
                       class="btn_view" title="Ver detalle">
                        <i class="far fa-eye"></i>
                    </a>
                    <a href="/SistemaVenta/sistema/factura.php?id=${venta.noventa}" 
                       target="_blank" class="btn_pdf" title="Factura PDF">
                        <i class="fas fa-file-invoice-dollar"></i>
                    </a>
                </td>
            </tr>`;
    });
    
    html += `</tbody></table>`;
    container.innerHTML = html;
}

/**
 * Actualiza el paginador
 * @param {Object} paginacion - Datos de paginación
 */
function actualizarPaginador(paginacion) {
    const container = document.getElementById('paginadorVentas');
    
    if (!paginacion || paginacion.total_paginas <= 1) {
        container.innerHTML = '';
        return;
    }
    
    let html = '<nav>';
    const filtros = obtenerFiltrosActuales();
    
    // Botón anterior
    if (paginacion.pagina_actual > 1) {
        html += `<a href="?${construirQueryString({...filtros, pagina: paginacion.pagina_actual - 1})}" 
                  class="pagina anterior">
                  <i class="fas fa-chevron-left"></i> Anterior
                </a>`;
    }
    
    // Info página actual
    html += `<span class="info-pagina">
                Página ${paginacion.pagina_actual} de ${paginacion.total_paginas}
             </span>`;
    
    // Botón siguiente
    if (paginacion.pagina_actual < paginacion.total_paginas) {
        html += `<a href="?${construirQueryString({...filtros, pagina: paginacion.pagina_actual + 1})}" 
                  class="pagina siguiente">
                  Siguiente <i class="fas fa-chevron-right"></i>
                </a>`;
    }
    
    html += '</nav>';
    container.innerHTML = html;
}

/**
 * Inicializa tooltips
 */
function initTooltips() {
    // Si usas Bootstrap tooltips, inicialízalos aquí
    // O implementa tooltips simples
    const tooltips = document.querySelectorAll('[title]');
    
    tooltips.forEach(el => {
        el.addEventListener('mouseenter', function(e) {
            // Implementación simple de tooltip
        });
    });
}

/**
 * Construye query string desde objeto
 * @param {Object} params - Parámetros
 * @returns {string} Query string
 */
function construirQueryString(params) {
    const searchParams = new URLSearchParams();
    
    // Parámetro fijo para MVC
    searchParams.set('url', 'ventas/listar');
    
    // Agregar otros parámetros
    Object.keys(params).forEach(key => {
        if (params[key] !== undefined && params[key] !== null && params[key] !== '') {
            searchParams.set(key, params[key]);
        }
    });
    
    return searchParams.toString();
}

/**
 * Formatea fecha
 * @param {string} fechaString - Fecha en string
 * @returns {string} Fecha formateada
 */
function formatFecha(fechaString) {
    const fecha = new Date(fechaString);
    return fecha.toLocaleDateString('es-ES', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

/**
 * Formatea moneda
 * @param {number} cantidad - Cantidad a formatear
 * @returns {string} Cantidad formateada
 */
function formatMoneda(cantidad) {
    return Number(cantidad).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');
}

/**
 * Escapa HTML para seguridad
 * @param {string} texto - Texto a escapar
 * @returns {string} Texto escapado
 */
function escapeHtml(texto) {
    const div = document.createElement('div');
    div.textContent = texto;
    return div.innerHTML;
}

// Hacer funciones disponibles globalmente
window.buscarVentas = buscarVentas;
window.cargarVentas = cargarVentas;
window.obtenerFiltrosActuales = obtenerFiltrosActuales;