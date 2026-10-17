#!/bin/sh
set -eu
printf '%s' "${BASIC_AUTH_USER:-}" | grep -Eq '^[A-Za-z0-9_-]{3,48}$' || { echo 'Usuario inválido'; exit 1; }
printf '%s' "${BASIC_AUTH_HASH:-}" | grep -Eq '^\$2[aby]\$(0[89]|1[0-6])\$[./A-Za-z0-9]{53}$' || { echo 'Configurar hash bcrypt válido (coste8-16)'; exit 1; }
caddy validate --config /opt/hefesto/Caddyfile --adapter caddyfile
exec caddy run --config /opt/hefesto/Caddyfile --adapter caddyfile
