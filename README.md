# SistemaVenta
Sistema de ventas completo en PHP.
app/controllers/   → Archivos que DECIDEN qué hacer
                     Ej: "si el usuario quiere ver ventas, mostrar ventas.php"
                     
app/models/        → Archivos que TRABAJAN con la base de datos
                     Ej: "obtener todas las ventas del día"
                     
app/core/          → Archivos que hace FUNCIONAR el sistema
                     Ej: conexión a BD, rutas, configuración
                     
app/helpers/       → Funciones UTILES que usamos en muchos lugares
                     Ej: formatear fecha, validar email

                     kk

                     views/layouts/     → Diseños BASE (header, footer, menú)
views/auth/        → Páginas de Login/Registro
views/modules/     → Cada módulo (ventas, productos, etc.)


public/            → Lo ÚNICO que el usuario ve directamente
public/assets/     → CSS, JS, imágenes que se cargan en el navegador
public/index.php   → La ÚNICA puerta de entrada a tu sistema