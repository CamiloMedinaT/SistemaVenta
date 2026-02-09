<?php 

	// Incluye el archivo de conexión a la base de datos
	include "../../conexion.php";

	// Inicia la sesión para usar variables de sesión
	session_start();

	// Línea usada para depuración de datos enviados por POST (comentada)
	//print_r($_POST);exit;

	// Cantidad de registros que se mostrarán por página
	$por_pagina = $_POST['cantidad'];

	// Verifica si se envió un texto de búsqueda
	if (isset($_POST['busqueda'])) {

		// Limpia la búsqueda para evitar inyección SQL
		$busqueda = mysqli_escape_string($conection,$_POST['busqueda']);

		// Consulta para contar el total de registros que coinciden con la búsqueda
		$sql_registe = mysqli_query($conection,"SELECT COUNT(*) as total_registro FROM cliente 
													WHERE (
															nit LIKE '%$busqueda%' OR 
															nombre LIKE '%$busqueda%') 
													AND status = 1 ");

		// Obtiene el resultado del conteo
		$result_register = mysqli_fetch_array($sql_registe);

		// Guarda el total de registros encontrados
		$total_registro = $result_register['total_registro'];

		// Si no se envía la página, se establece la primera
		if(empty($_POST['pagina']))
		{
			$pagina = 1;
		}else{
			// Página actual enviada por POST
			$pagina = $_POST['pagina'];
		}

		// Calcula desde qué registro empezar la consulta
		$desde = ($pagina-1) * $por_pagina;

		// Calcula el total de páginas necesarias
		$total_pagina = ceil($total_registro / $por_pagina);

		// Consulta para obtener los clientes según búsqueda y paginación
		$query = mysqli_query($conection,"SELECT * FROM cliente WHERE
											(
												nit LIKE '%$busqueda%' OR 
												nombre LIKE '%$busqueda%'
												 ) 
												AND
											status = 1 ORDER BY idcliente DESC LIMIT $desde,$por_pagina ");
	}

	// Obtiene la cantidad de registros devueltos
	$result = mysqli_num_rows($query);

	// Inicializa la variable de la paginación
	$lista = '';

	// Inicializa la variable del contenido de la tabla
	$detalleTabla = '';

	// Array donde se guardará la respuesta final
	$arrayData    = array();

	// Construye el encabezado de la tabla HTML
	$detalleTabla.='
					<table>
						<tr>
							<th>Ced.</th>
							<th>Nombre</th>
							<th>Teléfono</th>
							<th>Dirección</th>';

	// Muestra la columna de acciones solo si el rol es administrador o similar
	if ($_SESSION['rol'] == 1 || $_SESSION['rol'] == 2) {
		$detalleTabla.='<th>Acciones</th>';
	}

	// Verifica si existen resultados
	if ($result > 0) {

		// Recorre cada registro obtenido de la base de datos
		while ($data = mysqli_fetch_assoc($query)){

			// Agrega una fila con los datos del cliente
			$detalleTabla .= '</tr><tr>
								<td>'.$data['nit'].'</td>
								<td colspan="">'.$data['nombre'].'</td>
								<td class="">'.$data['telefono'].'</td>
								<td class="">'.$data['direccion'].'</td>';

			// Muestra botones de editar y eliminar según el rol
			if ($_SESSION['rol'] == 1 || $_SESSION['rol'] == 2) {
				$detalleTabla .= '<td class="">
									<a class="link_edit" id="editarCliente" href="javascript:editarCliente('.$data['idcliente'].');"><i class="fas fa-edit"></i> Editar</a>	
									 | 
									 <a class="link_delete" id="eliminarCliente" href="javascript:infoEliminarCliente('.$data['idcliente'].');"><i class="fas fa-trash-alt"></i> Eliminar</a>
									</td>
								 </tr>';
			}
		}

		// Cierra la tabla HTML
		$detalleTabla.='</table>';

		// Inicia la lista de paginación
		$lista.='<ul>';

		// Muestra botones de ir al inicio y retroceder
		if ($pagina > 1) {
			$lista.= '<li><a href="1"><i class="fas fa-step-backward"></i></a></li>
					  <li><a href="'.($pagina-1).'"><i class="fas fa-caret-left"></i></a></li>';
		}

		// Cantidad de páginas visibles antes y después de la actual
		$cant = 2;

		// Página inicial de la paginación
		$pagInicio = ($pagina > $cant) ? ($pagina - $cant) : 1;

		// Calcula el fin de la paginación
		if ($total_pagina > $cant)
		{
			$pagRestantes = $total_pagina - $pagina;
			$pagFin = ($pagRestantes > $cant) ? ($pagina + $cant) : $total_pagina;
		}
		else 
		{
			$pagFin = $total_pagina;
		}

		// Genera los enlaces numéricos de paginación
		for ($i=$pagInicio; $i <= $pagFin; $i++) 
		{ 
			if ($i == $pagina) 
			{
				$lista.= '<li class="pageSelected">'.$i.'</a></li>';	
			}else{
				$lista.= '<li><a href="'.$i.'">'.$i.'</a></li>';
			}
		}

		// Muestra botones de avanzar y última página
		if ($pagina < $pagFin) {
			$lista.= '<li><a href="'.($pagina+1).'"><i class="fas fa-caret-right"></i></a></li>
					  <li><a href="'.($total_pagina).'"><i class="fas fa-step-forward"></i></a></li>';
		}

		// Cierra la lista de paginación
		$lista.='</ul>';

		// Guarda la tabla en el array de respuesta
		$arrayData['detalle'] = $detalleTabla;

		// Guarda la paginación en el array de respuesta
		$arrayData['totales'] = $lista;

		// Devuelve los datos en formato JSON
		echo json_encode($arrayData,JSON_UNESCAPED_UNICODE);	               

	}else{
		// Mensaje de error si no hay resultados
		echo 'error';
	}

	// Cierra la conexión a la base de datos
	mysqli_close($conection);

	// Finaliza la ejecución del script
	exit;

?>
