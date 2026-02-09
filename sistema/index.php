<?php 

/**
 * ---------------------------------------------------------
 * INICIO DE SESIÓN
 * ---------------------------------------------------------
 * Se inicializa o reanuda una sesión existente.
 * Las sesiones permiten mantener información del usuario
 * entre distintas páginas del sistema (login, permisos, etc.).
 */
session_start();

?>
<!DOCTYPE html>
<html lang="en">
<head>
	<!--
		Define la codificación de caracteres UTF-8,
		permitiendo el uso correcto de acentos y caracteres especiales.
	-->
	<meta charset="UTF-8">

	<!--
		Incluye archivos externos necesarios para el sistema.
		Normalmente aquí se cargan:
		- Archivos CSS (estilos del sistema)
		- Librerías JavaScript (jQuery, Chart.js, Bootstrap, FontAwesome)
	-->
	<?php include "includes/scripts.php"; ?>

	<!-- Título que se muestra en la pestaña del navegador -->
	<title>Sistema Ventas</title>
</head>
<body>

	<?php 

		/**
		 * ---------------------------------------------------------
		 * INCLUSIÓN DE COMPONENTES DEL SISTEMA
		 * ---------------------------------------------------------
		 */

		// Carga el encabezado del sistema (menú, usuario logueado, logo)
		include "includes/header.php";

		// Carga el archivo de conexión a la base de datos MySQL
		include "../conexion.php";

		/**
		 * ---------------------------------------------------------
		 * DECLARACIÓN DE VARIABLES DE CONFIGURACIÓN DE LA EMPRESA
		 * ---------------------------------------------------------
		 * Estas variables almacenan la información general
		 * de la empresa (datos fiscales y de contacto)
		 * que se utiliza en diferentes módulos del sistema.
		 */

		$nit = '';              // Número de identificación tributaria
		$nombreEmpresa = '';    // Nombre comercial
		$razonSocial = '';      // Razón social legal
		$telEmpresa = '';       // Teléfono de contacto
		$emailEmpresa = '';     // Correo electrónico
		$dirEmpresa = '';       // Dirección física
		$iva = '';              // Porcentaje de IVA

		// Obtiene el ID del usuario autenticado desde la sesión
		$usuario_id = $_SESSION['idUser'];

		/**
		 * ---------------------------------------------------------
		 * CONSULTA DE DATOS DE CONFIGURACIÓN DE LA EMPRESA
		 * ---------------------------------------------------------
		 * Se consulta la tabla "configuracion" que contiene
		 * los datos generales del negocio.
		 */

		$query_empresa = mysqli_query($conection,"SELECT * FROM configuracion");

		// Verifica si existen registros en la consulta
		$row_empesa = mysqli_num_rows($query_empresa);

		if ($row_empesa > 0) 
		{
			// Recorre los registros obtenidos (normalmente solo uno)
			while ($arrInfoEmpresa = mysqli_fetch_assoc($query_empresa)) {

				// Asignación de valores provenientes de la base de datos
				$nit = $arrInfoEmpresa['nit'];
				$nombreEmpresa = $arrInfoEmpresa['nombre'];
				$razonSocial = $arrInfoEmpresa['razon_social'];
				$telEmpresa = $arrInfoEmpresa['telefono'];
				$emailEmpresa = $arrInfoEmpresa['email'];
				$dirEmpresa = $arrInfoEmpresa['direccion'];
				$iva = $arrInfoEmpresa['iva'];
			//	$foto1 = $arrInfoEmpresa['foto'];
				$moned = $arrInfoEmpresa['moneda'];
			}

			/**
			 *Validación y carga de la imagen de la empresa
			 */
			$foto = '';
			$classRemove = 'notBlock';

			if ($foto1 != '') {
				$classRemove = '';
				$foto = '<img id="img" src="factura/img/'.$foto1.'" alt="Producto">';
			}
		}

		/**
		 * ---------------------------------------------------------
		 * VARIABLES DEL PANEL DE CONTROL (CAJA)
		 * ---------------------------------------------------------
		 * Estas variables almacenan los valores financieros
		 * que se muestran en el dashboard del sistema.
		 */

		$inicio 	= '0.00'; // Monto inicial de caja
		$ventas 	= '0.00'; // Total de ventas realizadas
		$abonos 	= '0.00'; // Pagos parciales recibidos
		$creditos 	= '0.00'; // Ventas a crédito
		$egreso 	= '0.00'; // Gastos realizados
		$total 		= '0.00'; // Total final de caja

		/**
		 * Consulta para verificar si existe una caja abierta
		 */
		$query_caja = mysqli_query($conection,"SELECT * FROM caja WHERE status = 1");
		$result_caja = mysqli_num_rows($query_caja);

		if ($result_caja > 0) {

			// Obtiene los datos de la caja activa
			$data_caja = mysqli_fetch_assoc($query_caja);
			$id_caja = $data_caja['id'];

			/**
			 * Llamado a un procedimiento almacenado
			 * que devuelve los valores financieros
			 * del dashboard.
			 */
			$query_dash = mysqli_query($conection,"CALL dataDashboard($id_caja);");
			$result_das = mysqli_num_rows($query_dash);

			if ($result_das > 0) {

				// Asignación de valores obtenidos del procedimiento
				$data_dash = mysqli_fetch_assoc($query_dash);
				$inicio = $data_dash['inicios'];
				$ventas = $data_dash['ventas'];
				$abonos = $data_dash['abonos'];
				$creditos = $data_dash['credito'];
				$egreso = $data_dash['egreso'];

				// Cálculo del total final de caja
				$total = $inicio + $ventas + $abonos - $egreso;

				// Cierre de conexión a la base de datos
				mysqli_close($conection);
			}

			/**
			 * Normalización de valores para evitar mostrar ceros nulos
			 */
			if ($inicio == 0) { $inicio = '0.00'; }
			if ($ventas == 0) { $ventas = '0.00'; }
			if ($abonos == 0) { $abonos = '0.00'; }
			if ($creditos == 0) { $creditos = '0.00'; }
			if ($egreso == 0) { $egreso = '0.00'; }
		}
	?>

	<!--
		SECCIÓN PRINCIPAL DEL PANEL DE CONTROL
		Muestra los indicadores financieros principales
	-->
	<section id="container">
		<div class="divContainer">
			<h1 class="titlePanelControl">Panel de control</h1>

			<div class="dashboard">
				<!-- Cada bloque representa un indicador del sistema -->
				<a href="#"><strong>Inicio:</strong> <?= $moned.' '.$inicio; ?></a>
				<a href="ventas.php"><strong>Ventas:</strong> <?= $moned.' '.$ventas; ?></a>
				<a href="#"><strong>Abonos:</strong> <?= $moned.' '.$abonos; ?></a>
				<a href="#"><strong>Créditos:</strong> <?= $moned.' '.$creditos; ?></a>
				<a href="#"><strong>Gastos:</strong> <?= $moned.' '.$egreso; ?></a>
				<a href="#"><strong>Total cierre:</strong> <?= $moned.' '.$total; ?></a>
			</div>
		</div>

		<!-- SECCIÓN DE GRÁFICOS ESTADÍSTICOS -->
		<div class="divInfoSistema">
			<h1 class="titlePanelControl">Reporte gráfico de movimientos</h1>

			<div class="containerPerfil">
				<div class="containerDataUser">
					<canvas id="myChart"></canvas>
				</div>
				<div class="containerDataEmpresa">
					<canvas id="myChartStokMin"></canvas>
				</div>
			</div>
		</div>
	</section>

	<!-- PIE DE PÁGINA -->
	<?php include "includes/footer.php"?>

</body>
</html>

<script>
/**
 * ---------------------------------------------------------
 * SECCIÓN JAVASCRIPT – GRÁFICOS ESTADÍSTICOS
 * ---------------------------------------------------------
 * Se utilizan peticiones AJAX y la librería Chart.js
 * para mostrar gráficos dinámicos.
 */

// Inicializa la carga de gráficos
cargarDatosGraficoBar();
cargarDatosGraficoBarStokMin();

/**
 * Obtiene los productos con stock mínimo
 */
function cargarDatosGraficoBarStokMin(){
	$.ajax({
		url:'action/data_grafico_stok_min.php',
		type:'POST'
	}).done(function(resp){
		if (resp.length > 0) {
			var data = JSON.parse(resp);
			var titulo = [];
			var cantidad = [];
			var colores = [];

			for(var i = 0; i < data.length; i++){
				titulo.push(data[i][2]);
				cantidad.push(data[i][6]);
				colores.push(colorRGB());
			}

			CrearGrafico(titulo,cantidad,colores,'doughnut','Productos con Stock Mínimo','myChartStokMin');
		}
	});
}

/**
 * Obtiene los productos más vendidos
 */
function cargarDatosGraficoBar(){
	$.ajax({
		url:'action/data_grafico.php',
		type:'POST'
	}).done(function(resp){
		if (resp.length > 0) {
			var data = JSON.parse(resp);
			var titulo = [];
			var cantidad = [];
			var colores = [];

			for(var i = 0; i < data.length; i++){
				titulo.push(data[i][0]);
				cantidad.push(data[i][1]);
				colores.push(colorRGB());
			}

			CrearGrafico(titulo,cantidad,colores,'doughnut','Productos más vendidos','myChart');
		}
	});
}

/**
 * Crea gráficos usando Chart.js
 */
function CrearGrafico(titulo,cantidad,colores,tipo,encabezado,id){
	new Chart(document.getElementById(id), {
		type: tipo,
		data: {
			labels: titulo,
			datasets: [{
				label: encabezado,
				data: cantidad,
				backgroundColor: colores
			}]
		}
	});
}

/**
 * Funciones auxiliares para generar colores aleatorios
 */
function generarNumero(numero){
	return (Math.random()*numero).toFixed(0);
}

function colorRGB(){
	return "rgb("+generarNumero(255)+","+generarNumero(255)+","+generarNumero(255)+")";
}
</script>
