#!/usr/bin/env bash
# scripts/coolify-check.sh
# Verifica que compose.yaml cumple el contrato Coolify del kit Hefesto.
# Comprueba los puntos 1 y 2 del contrato en los servicios sin profiles.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$ROOT/compose.yaml"
BASE_DIR="$ROOT"

TMP_ENV="$(mktemp -t coolify-check-env.XXXXXX)"
RENDER="$(mktemp -t coolify-check-render.XXXXXX)"
trap 'rm -f "$TMP_ENV" "$RENDER"' EXIT

# 1. Generar .env temporal con valores ficticios no secretos para cada ${VAR}
#    del compose. Para BASIC_AUTH_HASH se usa un hash bcrypt valido con $$
#    para que docker compose no intente interpolar los $ internos.
VARS=$(grep -oE '\$\{[A-Z_][A-Z0-9_]*[^}]*\}' "$COMPOSE_FILE" \
    | sed -E 's/^\$\{([A-Z_][A-Z0-9_]*).*/\1/' \
    | sort -u)

: > "$TMP_ENV"
for v in $VARS; do
    case "$v" in
        *_URL|*_HOST)
            printf '%s=https://ejemplo.invalid\n' "$v" >> "$TMP_ENV"
            ;;
        BASIC_AUTH_HASH)
            # Bcrypt $2a$12$ + 53 chars base64 (60 chars total).
            printf 'BASIC_AUTH_HASH=$$2a$$12$$LwqV5vBnLWhJBOI5ltJ4Su2u8x3yF5xQfC9xT5N8K0pQqS8tT0OxK\n' >> "$TMP_ENV"
            ;;
        *)
            printf '%s=x1234567890abcdefghij\n' "$v" >> "$TMP_ENV"
            ;;
    esac
done

# 2. Renderizar el compose. Debe terminar sin error.
if ! docker compose --project-directory "$BASE_DIR" -f "$COMPOSE_FILE" \
        --env-file "$TMP_ENV" config --format json > "$RENDER" 2> "$RENDER.stderr"; then
    echo "compose: fallo al renderizar"
    cat "$RENDER.stderr" >&2
    exit 1
fi

ERR=0

# Punto 2: raiz sin name fijo. Si la raiz trae 'name' debe coincidir con el
# nombre del directorio del proyecto; cualquier otro valor viene del compose
# fuente y bloquea que Coolify defina el nombre.
PROJECT_DIR_NAME=$(basename "$BASE_DIR")
ACTUAL_NAME=$(jq -r '.name // empty' "$RENDER")
if [ -n "$ACTUAL_NAME" ] && [ "$ACTUAL_NAME" != "$PROJECT_DIR_NAME" ]; then
    echo "compose: name raiz fijo ($ACTUAL_NAME) - Coolify pone el nombre de proyecto (esperado implicito: $PROJECT_DIR_NAME) (punto 2)"
    ERR=1
fi

# Redes top-level sin name fijo. Los nombres auto-generados siguen
# <proyecto>_<clave>; cualquier otra cosa viene del compose fuente.
NETWORK_KEYS=$(jq -r '.networks // {} | keys[]' "$RENDER" 2>/dev/null || true)
for net in $NETWORK_KEYS; do
    EXPECTED_NET="${ACTUAL_NAME:-${PROJECT_DIR_NAME}}_${net}"
    NET_NAME=$(jq -r ".networks[\"$net\"].name // empty" "$RENDER")
    if [ -n "$NET_NAME" ] && [ "$NET_NAME" != "$EXPECTED_NET" ]; then
        echo "compose: red '$net' tiene name fijo '$NET_NAME' (esperado: $EXPECTED_NET) (punto 2)"
        ERR=1
    fi
done

# Volumenes top-level sin name fijo (misma logica).
VOL_KEYS=$(jq -r '.volumes // {} | keys[]' "$RENDER" 2>/dev/null || true)
for vol in $VOL_KEYS; do
    EXPECTED_VOL="${ACTUAL_NAME:-${PROJECT_DIR_NAME}}_${vol}"
    VOL_NAME=$(jq -r ".volumes[\"$vol\"].name // empty" "$RENDER")
    if [ -n "$VOL_NAME" ] && [ "$VOL_NAME" != "$EXPECTED_VOL" ]; then
        echo "compose: volumen '$vol' tiene name fijo '$VOL_NAME' (esperado: $EXPECTED_VOL) (punto 2)"
        ERR=1
    fi
done

# Servicios sin profiles: comprobaciones del punto 1.
SERVICES=$(jq -r '.services | keys[]' "$RENDER")
for svc in $SERVICES; do
    if jq -e ".services[\"$svc\"].profiles" "$RENDER" >/dev/null 2>&1; then
        continue
    fi

    # 1a. Campos prohibidos.
    for field in ports container_name privileged cap_add devices; do
        if jq -e ".services[\"$svc\"].$field" "$RENDER" >/dev/null 2>&1; then
            echo "$svc: campo prohibido '$field' (punto 1)"
            ERR=1
        fi
    done

    # 1b. Modos host prohibidos.
    NM=$(jq -r ".services[\"$svc\"].network_mode // empty" "$RENDER")
    [ "$NM" = "host" ] && { echo "$svc: network_mode host (punto 1)"; ERR=1; }
    PID=$(jq -r ".services[\"$svc\"].pid // empty" "$RENDER")
    [ "$PID" = "host" ] && { echo "$svc: pid host (punto 1)"; ERR=1; }
    IPC=$(jq -r ".services[\"$svc\"].ipc // empty" "$RENDER")
    [ "$IPC" = "host" ] && { echo "$svc: ipc host (punto 1)"; ERR=1; }

    # 1c. security_opt con unconfined.
    SEC=$(jq -r ".services[\"$svc\"].security_opt // [] | .[]" "$RENDER" 2>/dev/null || true)
    if printf '%s\n' "$SEC" | grep -qx 'unconfined'; then
        echo "$svc: security_opt unconfined (punto 1)"
        ERR=1
    fi

    # 1d. binds fuera del repo o con docker.sock.
    VOL_ARR=$(jq -c ".services[\"$svc\"].volumes // [] | .[]" "$RENDER" 2>/dev/null || true)
    while IFS= read -r vol; do
        [ -z "$vol" ] && continue
        SRC=$(printf '%s' "$vol" | jq -r '.source // empty')
        TYP=$(printf '%s' "$vol" | jq -r '.type // "bind"')
        [ "$TYP" != "bind" ] && continue
        case "$SRC" in
            *docker.sock*)
                echo "$svc: bind a docker.sock (punto 1)"
                ERR=1
                ;;
            /*)
                case "$SRC" in
                    "$ROOT"/*) ;;
                    *) echo "$svc: bind fuera del repo: $SRC (punto 1)"; ERR=1 ;;
                esac
                ;;
        esac
    done <<< "$VOL_ARR"
done

if [ "$ERR" -ne 0 ]; then
    echo "FAIL: compose no cumple el contrato Coolify"
    exit 1
fi

echo "OK: compose cumple contrato Coolify"