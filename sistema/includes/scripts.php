<!-- Define cómo se adapta la página a diferentes tamaños de pantalla (responsive) -->
<!-- Evita el zoom del usuario y fija la escala inicial -->
<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">

<!-- Carga la hoja de estilos principal del sitio -->
<!-- El ?1.0 ayuda a evitar problemas de caché del navegador -->
 <link rel="stylesheet" type="text/css" href="cses/modventas.css?1.0" media="all">
<link rel="stylesheet" type="text/css" href="css/style.css?1.0" media="all">

<!-- Carga los estilos para diseño adaptable a móviles y tablets -->
<link rel="stylesheet" type="text/css" href="css/responsive.css?1.0" media="all">

<!-- Carga los estilos necesarios para las gráficas de Chart.js -->
<link rel="stylesheet" type="text/css" href="js/Chart.min.css">

<!-- Carga la librería jQuery (versión minimizada) -->
<!-- Facilita el manejo del DOM, eventos, animaciones y AJAX -->
<script type="text/javascript" src="js/jquery.min.js"></script>

<!-- Carga otra versión específica de jQuery -->
<!-- NO es recomendable cargar dos versiones porque puede causar conflictos -->
<script type="text/javascript" src="js/jquery-1.12.1.js"></script>

<!-- Carga los estilos visuales de jQuery UI -->
<!-- Necesarios para componentes como calendarios, diálogos y sliders -->
<link rel="stylesheet" type="text/css" href="js/jquery-ui.css">

<!-- Carga la librería jQuery UI -->
<!-- Agrega componentes gráficos e interacciones avanzadas -->
<script type="text/javascript" src="js/jquery-ui.js"></script>

<!-- Archivo JavaScript personalizado -->
<!-- Generalmente usado para manejar iconos o recursos gráficos -->
<script type="text/javascript" src="js/icons.js"></script>

<!-- Archivo JavaScript principal del proyecto -->
<!-- Contiene funciones personalizadas y lógica del sitio -->
<script type="text/javascript" src="js/functions.js"></script>

<!-- Carga Chart.js junto con todas sus dependencias -->
<!-- Se utiliza para crear gráficas dinámicas -->
<script type="text/javascript" src="js/Chart.bundle.min.js"></script>

<!-- Carga nuevamente Chart.js en versión minimizada -->
<!-- Es redundante si ya se usa Chart.bundle.min.js -->
<script type="text/javascript" src="js/Chart.min.js"></script>	

<!-- Incluye el archivo PHP functions.php en el servidor -->
<!-- Permite reutilizar funciones y lógica del backend -->




<?php include "functions.php"; ?>
