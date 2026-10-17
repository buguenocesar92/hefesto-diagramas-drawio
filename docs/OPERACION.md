# Operación
## Respaldo y recuperación
Ejecutar `python3 scripts/backup.py` desde cualquier ubicación. Copia `.env`, ambos Compose y los archivos de gateway; genera un manifiesto con SHA-256. El respaldo contiene el hash de acceso: guardarlo cifrado fuera del servidor. No incluye diagramas del navegador, archivos descargados, imágenes Docker ni configuración de Coolify/DNS/TLS.

Guardar los diagramas `.drawio` explícitamente en una carpeta de cliente respaldada. No confiar en el almacenamiento del navegador como única copia.

Para recuperar configuración en carpeta nueva:
`python3 scripts/restore.py /ruta/respaldo /ruta/destino-nuevo`

El script rechaza archivos manipulados, rutas fuera del respaldo y destinos no vacíos. Recupera solo configuración; copiar adicionalmente documentación, scripts y plantillas desde este ZIP. Revisar el hash y arrancar por túnel privado. Las imágenes fijadas deben seguir disponibles en el registro; archivarlas por separado si se requiere recuperación sin Internet.

## Actualización
Guardar diagramas y respaldo, revisar notas upstream, cambiar tag y digest juntos en un clon, probar apertura/guardado/exportación de una copia. Recrear los contenedores tras validación. Conservar Compose anterior para revertir. No usar `latest` sin fijar digest.

## Comprobaciones de aceptación
- Sin credenciales: 401; con contraseña incorrecta: 401; con correcta: editor.
- App sin puertos públicos; entrada pública solo HTTPS al gateway.
- Abrir cada plantilla, editar texto, descargar .drawio, cerrar y reabrir el archivo: se conservan cambios.
- Exportar SVG/PNG y revisar etiquetas y flechas. PDF mediante navegador; no hay export-server.
- Confirmar ausencia de errores JavaScript/CSP que impidan operaciones básicas. No ampliar CSP indiscriminadamente: revisar el recurso requerido.
- Hacer respaldo y restaurarlo en una carpeta vacía; probar nuevo arranque privado.
- Reiniciar contenedores y confirmar acceso; los archivos locales siguen siendo responsabilidad del usuario.
