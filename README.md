# Hefesto Diagramas · draw.io 32.4.1
Kit de evaluación para un editor de diagramas autoalojado, con Caddy y contraseña de acceso. Imágenes fijadas por digest; no incluye las imágenes Docker dentro del ZIP.

## Qué entrega
- Compose para Coolify, puerta de entrada con Basic Auth y red interna para draw.io.
- Editor en español y modo offline en la ruta raíz. Sin integraciones cloud ni claves de IA.
- Tres plantillas `.drawio` editables: arquitectura Hefesto, entrega al cliente y despliegue con restauración.
- Scripts de copia y restauración de configuración, instrucciones de operación y traspaso.

## Inicio privado
Requisitos: Linux, Docker Engine con Compose v2, Python 3; acceso para descargar imágenes. Como presupuesto inicial de prueba, reservar 2 GB RAM y 2 CPU y medir el consumo real.

1. Descomprimir y entrar en esta carpeta.
2. Ejecutar `python3 scripts/configure.py`. No sobrescribe un `.env` existente.
3. Generar un hash con el comando siguiente; la contraseña se introduce interactivamente:

```sh
docker run --rm -it caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f caddy hash-password --algorithm bcrypt --bcrypt-cost 12
```

4. Editar `.env`: usuario de 3–48 caracteres alfanuméricos, guion o guion bajo; pegar el hash bcrypt conservando las comillas simples del ejemplo. No guardar la contraseña en el repositorio.
5. Validar y levantar:

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml config --quiet
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d
```

6. Desde tu equipo, abrir un túnel `ssh -L 8109:127.0.0.1:8109 usuario@servidor` y visitar `http://localhost:8109/?offline=1&lang=es&https=0`. En el propio servidor basta localhost. El gateway impone offline y español en la raíz; el parámetro https=0 no es necesario para el flujo sin OAuth.
7. Introducir las credenciales; abrir una plantilla con Archivo → Abrir desde → Dispositivo. Guardar una copia `.drawio` en tu equipo. Probar también SVG y PNG; PDF depende de la impresión del navegador.

## Publicar en Coolify
Importar esta carpeta mediante un repositorio privado como recurso Docker Compose. Usar exclusivamente `compose.yaml` y mantener `ops/` en el checkout; el gateway necesita ese montaje. Introducir BASIC_AUTH_USER y BASIC_AUTH_HASH como variables del recurso: el hash literal sin comillas envolventes en el formulario. No exponer app ni publicar 8080/8443 directamente.

El hash bcrypt contiene caracteres `$` que Coolify interpreta como variable de Compose; en el formulario del recurso marcar `BASIC_AUTH_HASH` como **literal** (toggle «Value is a literal / No variable interpolation») o duplicar cada `$` como `$$` al pegarlo. El hash tiene la forma `$2[aby]$(coste)$<base64>`, con coste 08 a 16; el `ops/start.sh` del contenedor rechaza cualquier valor que no cumpla esa forma.

Asignar un subdominio HTTPS únicamente al servicio **gateway**, puerto **8080**. TLS termina en Coolify; Caddy recibe tráfico interno HTTP. No usar una subruta. El servicio app permanece en la red interna. No copiar el override bootstrap al despliegue público. Confirmar desde fuera que sin contraseña se obtiene 401 y que no existe acceso directo a app. Para checks HTTP de Coolify, no configurar un chequeo anónimo que exija 200: Basic Auth devuelve 401; revisar salud autenticada sin escribir secretos en logs.

## Despliegue en Coolify (MVP Hefesto)

Importar esta carpeta como recurso **Docker Compose** apuntando a `compose.yaml`; Coolify detecta el servicio `gateway` y le asigna el subdominio. Mantener `ops/` en el checkout: el gateway lo monta como volumen de solo lectura.

**Variables obligatorias del recurso**

- `BASIC_AUTH_USER`: usuario de 3–48 caracteres alfanuméricos, guion o guion bajo; lo valida `ops/start.sh`.
- `BASIC_AUTH_HASH`: hash bcrypt. Coolify interpreta los `$` del hash como variable de Compose, así que en el formulario del recurso marcar `BASIC_AUTH_HASH` como **literal** (toggle «Value is a literal / No variable interpolation») o duplicar cada `$` como `$$` al pegarlo. La forma esperada es `$2[aby]$(coste)$<base64>` con coste 08 a 16; cualquier valor que no cumpla eso es rechazado por `ops/start.sh`.

**Servicio y healthcheck**

Coolify debe enrutar el subdominio al servicio `gateway` en el puerto **`8080`** (TLS termina en Coolify/Traefik; Caddy recibe HTTP interno). El gateway lleva `healthcheck` propio que no usa credenciales:

```yaml
healthcheck:
  test: ["CMD-SHELL", "nc -z 127.0.0.1 8080 || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 3
```

Un chequeo HTTP anónimo no sirve: Basic Auth responde `401` aunque el servicio este sano. La imagen `caddy:2-alpine` trae busybox con `nc`, por eso se chequea el puerto en vez del código HTTP. El servicio `app` permanece en la red interna y no se publica.

### Verificacion del contrato Coolify
Tras cualquier cambio en `compose.yaml`, ejecutar `bash scripts/coolify-check.sh` desde la raiz del repositorio. El script genera un `.env` temporal con valores ficticios, renderiza el compose con un nombre de proyecto unico y valida los puntos 1 y 2 del contrato (sin `ports`, `container_name`, `network_mode: host`, `docker.sock`, `security_opt` con `unconfined`, ni `name:` fijos en la raiz, redes o volumenes). Termina con `OK: compose cumple contrato Coolify` y exit 0 si todo esta en orden.

## Datos y límites
Los documentos viven donde el usuario los guarde: dispositivo o almacenamiento del navegador. Este kit NO proporciona repositorio central, colaboración en tiempo real, usuarios individuales, roles o MFA. Basic Auth es una barrera compartida y el navegador puede recordar la sesión; no hay botón de cierre de sesión fiable. Crear una instancia por cliente si necesitan credenciales separadas.

No necesita Supabase: añadir PostgreSQL no le proporciona persistencia nativa. Para archivo central, guardar los `.drawio` en Nextcloud o adjuntarlos a Odoo mediante sus interfaces. Esto es un procedimiento de entrega, no una integración automática instalada. Ver `docs/TRASPASO.md`.

La política CSP restringe recursos a este origen; imágenes remotas, fuentes externas, IA y conectores no forman parte del servicio. Usar imágenes importadas desde archivos. La red interna bloquea salida del contenedor; CSP restringe el navegador, pero no constituye aislamiento completo del equipo del usuario.

El repositorio oficial describe su imagen como versión de evaluación y ofrece una versión comercial para producción. Este ZIP se entrega como kit para evaluar; antes de ofrecer un servicio con SLA, revisar la distribución soportada y sus condiciones. No se ha ejecutado Docker ni una prueba visual en este entorno. Ver `docs/VALIDACION.md` antes de usarlo con clientes.
