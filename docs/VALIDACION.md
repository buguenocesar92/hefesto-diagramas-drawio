# Validación del kit
Comprobado localmente: sintaxis Python y shell; parseo de ambos YAML; XML de las tres plantillas, IDs únicos y referencias de aristas; creación de .env con permisos 0600 y rechazo de sobrescritura; respaldo/restauración de configuración en carpeta temporal; rechazo de destino no vacío y archivo manipulado; integridad del ZIP.

Pendiente en servidor de prueba: Docker Compose config, descarga y arranque de imágenes, validación de Caddy en su binario, prueba de autenticación/HTTPS, compatibilidad de CSP con el navegador, revisión visual de plantillas, guardar/reabrir/exportar diagramas y despliegue Coolify. No se ejecutó Docker ni se ha publicado un servicio. No hay Supabase conectado ni integración automática con Odoo.
