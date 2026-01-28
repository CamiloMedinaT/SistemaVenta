<?php 

	// Variable para almacenar mensajes de alerta (errores de login)
	$alert = '';

	// Inicia o reanuda la sesión del usuario
	session_start();

	// Verifica si ya existe una sesión activa
	if(!empty($_SESSION['active']))
	{
		// Si el usuario ya está logueado, lo redirige al sistema
		header('location: sistema/');
	}
	else
	{
		// Verifica si el formulario fue enviado (POST no está vacío)
		if(!empty($_POST))
		{
			// Valida que los campos usuario y clave no estén vacíos
			if(empty($_POST['usuario']) || empty($_POST['clave']))
			{
				// Mensaje de error si faltan datos
				$alert = 'No has ingresado datos completos';
			}
			else
			{
				// Incluye el archivo de conexión a la base de datos
				require_once "conexion.php";

				// Limpia el usuario para evitar inyección SQL
				$user = mysqli_real_escape_string($conection, $_POST['usuario']);

				// Limpia la contraseña y la encripta con MD5
				$pass = md5(mysqli_real_escape_string($conection, $_POST['clave']));

				// Consulta SQL para verificar el usuario y obtener su rol
				$query = mysqli_query(
					$conection,
					"SELECT u.idusuario, u.nombre, u.correo, u.usuario, r.idrol, r.rol 
					 FROM usuario u 
					 INNER JOIN rol r
					 ON u.rol = r.idrol
					 WHERE usuario = '$user' AND clave = '$pass'"
				);

				// Cierra la conexión a la base de datos
				mysqli_close($conection);

				// Obtiene la cantidad de registros encontrados
				$result = mysqli_num_rows($query);

				// Si se encontró al menos un usuario
				if($result > 0)
				{
					// Obtiene los datos del usuario
					$data = mysqli_fetch_array($query);

					// Crea la sesión activa
					$_SESSION['active'] = true;

					// Guarda los datos del usuario en la sesión
					$_SESSION['idUser']   = $data['idusuario'];
					$_SESSION['nombre']   = $data['nombre'];
					$_SESSION['email']    = $data['correo'];
					$_SESSION['user']     = $data['usuario'];
					$_SESSION['rol']      = $data['idrol'];
					$_SESSION['rol_name'] = $data['rol'];

					// Redirige al sistema principal
					header('location: sistema/');
				}
				else
				{
					// Mensaje de error si las credenciales son incorrectas
					$alert = 'El Usuario o contraseña son incorrectos';

					// Destruye cualquier sesión existente
					session_destroy();
				}
			}
		}	
	}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Configuración de codificación de caracteres -->
    <meta charset="utf-8">

    <!-- Configuración responsive para dispositivos móviles -->
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    
    <!-- Meta tags para prevenir caché -->
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">

    <!-- Título de la página -->
    <title>Login | Sistema de ventas Aurora</title>

    <!-- Enlace al archivo de estilos CSS -->
    <link rel="stylesheet" type="text/css" href="css/style.css?1.0" media="all">
</head>
<body>
    <!-- Contenedor principal del formulario -->
    <section id="container">
        <!-- Formulario de inicio de sesión -->
        <form action="" method="post" autocomplete="off">
            <!-- Título del formulario -->
            <h3>Iniciar Sesión</h3>

            <!-- Imagen de login -->
            <img src="img/1.png" alt="Login">

            <!-- Campo para ingresar el usuario -->
            <input type="text" name="usuario" placeholder="Usuario" autocomplete="off">

            <!-- Campo para ingresar la contraseña -->
            <input type="password" name="clave" placeholder="Contraseña" autocomplete="off">

            <!-- Muestra mensajes de alerta -->
            <div class="alert">
                <?php echo isset($alert) ? $alert : ''; ?>
            </div>

            <!-- Botón para enviar el formulario -->
            <input type="submit" value="INGRESAR">
        </form>
    </section>
</body>
</html>