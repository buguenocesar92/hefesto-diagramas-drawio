# ayudante: kit de pruebas aislado para este repo.
#
# Nunca toca el .env real ni Docker real: el kit se copia a un directorio
# temporal con un .env sintetico y los stubs de tests/stubs/ responden por
# Docker.
RAIZ="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export RAIZ
export HEFESTO_KIT_TEST=1
export PATH="$RAIZ/tests/stubs:$PATH"

preparar_kit() {
  KIT="$BATS_TEST_TMPDIR/kit"
  rm -rf "$KIT"
  mkdir -p "$KIT"
  cp -R "$RAIZ/scripts" "$KIT/scripts"
  rm -rf "$KIT/scripts/__pycache__"
  if [ -f "$RAIZ/compose.yaml" ]; then cp "$RAIZ/compose.yaml" "$KIT/compose.yaml"; fi
  if [ -f "$RAIZ/compose.bootstrap.yaml" ]; then cp "$RAIZ/compose.bootstrap.yaml" "$KIT/compose.bootstrap.yaml"; fi
  mkdir -p "$KIT/ops"
  printf ":8080 {\n}\n" > "$KIT/ops/Caddyfile"
  printf "#!/bin/sh\n" > "$KIT/ops/start.sh"
  mkdir -p "$KIT/backups"
  printf 'SECRETO_DE_PRUEBA=valor-ficticio-no-real\nVOLUME_PREFIX=prueba\n' > "$KIT/.env"
  chmod 600 "$KIT/.env"
  export KIT
}

preparar_datos() {
  export STUB_DUMP_FILE="$BATS_TEST_TMPDIR/dump.sql"
  printf -- '-- dump sintetico\nCREATE TABLE demo(id int);\n' > "$STUB_DUMP_FILE"
  export STUB_TAR_DIR="$BATS_TEST_TMPDIR/tar"
  mkdir -p "$STUB_TAR_DIR/data"
  printf 'archivo sintetico\n' > "$STUB_TAR_DIR/data/demo.txt"
  export STUB_RUNNING=1
  export STUB_FIND_OUTPUT=""
  export STUB_PSQL_OUT=0
  export STUB_SERVICES="app"
}

generar_receptor_age() {
  # Genera un par de claves age efimero SOLO en el directorio temporal de la
  # prueba. Nunca se versiona ni se usa fuera de la suite.
  if ! command -v age-keygen >/dev/null 2>&1; then
    return 1
  fi
  local dir="$BATS_TEST_TMPDIR/age"
  mkdir -p "$dir"
  chmod 700 "$dir"
  # age-keygen escribe la clave publica en stderr y la deja en el encabezado
  # del archivo de clave privada.
  if ! age-keygen -o "$dir/clave.txt" >/dev/null 2>&1; then
    return 1
  fi
  AGE_RECIPIENT="$(sed -n 's/^# public key: //p' "$dir/clave.txt")"
  export AGE_RECIPIENT
  [ -n "$AGE_RECIPIENT" ]
}
