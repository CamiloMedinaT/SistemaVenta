<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    
    <title>Login | Sistema de ventas Aurora</title>
    
    <!-- CSS ORIGINAL de tu sistema (ruta absoluta) -->
    <link rel="stylesheet" type="text/css" href="/SistemaVenta/css/style.css?1.0" media="all">
    
    <!-- Estilos de emergencia si CSS no carga -->
    <style>
        body { font-family: Arial; margin: 0; background: #f2f2f2; }
        #container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h3 { text-align: center; color: #333; margin-bottom: 20px; }
        img { display: block; margin: 0 auto 20px; max-width: 100px; }
        input[type="text"], input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 3px; box-sizing: border-box; }
        input[type="submit"] { width: 100%; padding: 12px; background: #5cb85c; color: white; border: none; border-radius: 3px; cursor: pointer; font-size: 16px; margin-top: 10px; }
        input[type="submit"]:hover { background: #4cae4c; }
        .alert { color: #a94442; background: #f2dede; border: 1px solid #ebccd1; padding: 10px; border-radius: 3px; margin: 15px 0; text-align: center; }
        .debug { font-size: 12px; color: #666; text-align: center; margin-top: 15px; }
    </style>
</head>
<body>
    <section id="container">
        <!-- Formulario que envía al controlador MVC -->
        <form action="/SistemaVenta/public/index.php?url=auth/procesarLogin" method="post" autocomplete="off">
            <h3>Iniciar Sesión</h3>
            
            <!-- Imagen original de tu sistema -->
            <img src="/SistemaVenta/img/1.png" alt="Login">
            
            <!-- Campos del formulario -->
            <input type="text" name="usuario" placeholder="Usuario" required autocomplete="off" autofocus>
            <input type="password" name="clave" placeholder="Contraseña" required autocomplete="off">
            
            <!-- Mostrar mensajes de error -->
            <?php if (isset($_SESSION['alert'])): ?>
                <div class="alert"><?php echo $_SESSION['alert']; unset($_SESSION['alert']); ?></div>
            <?php endif; ?>
            
            <!-- Botón de enviar -->
            <input type="submit" value="INGRESAR">
            
            <!-- Indicador de que es el sistema nuevo -->
            <div class="debug">
                Sistema MVC v2.0 | Login migrado
            </div>
        </form>
    </section>
</body>
</html>