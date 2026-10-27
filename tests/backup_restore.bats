#!/usr/bin/env bats
load 'ayudante'

setup() {
  preparar_kit
  preparar_datos
}

teardown() {
  rm -rf "$BATS_TEST_TMPDIR/kit"
}

@test "el respaldo genera manifest.json con las cinco claves del contrato" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  [ -f "$RESPALDO/manifest.json" ]
  run python3 -c "import json,sys; m=json.load(open(sys.argv[1])); falta=[k for k in ('software','version','database','sha256','status') if k not in m]; assert not falta, falta; assert m['status']=='completed', m['status']; assert m['software']=='hefesto-diagramas', m['software']" "$RESPALDO/manifest.json"
  [ "$status" -eq 0 ]
}

@test "el .env no queda en claro en el respaldo" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  [ ! -f "$RESPALDO/.env" ]
  [ -f "$RESPALDO/env.vars" ]
  run grep -F "SECRETO_DE_PRUEBA" "$RESPALDO/env.vars"
  [ "$status" -eq 0 ]
  run grep -R -F "valor-ficticio-no-real" "$RESPALDO"
  [ "$status" -ne 0 ]
}

@test "con receptor age el .env viaja cifrado" {
  if ! generar_receptor_age; then skip "age-keygen no disponible en este entorno"; fi
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  [ -f "$RESPALDO/env.age" ]
  run grep -R -F "valor-ficticio-no-real" "$RESPALDO"
  [ "$status" -ne 0 ]
}

@test "check_backup acepta el respaldo integro" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  run python3 "$KIT/scripts/check_backup.py" "$RESPALDO"
  [ "$status" -eq 0 ]
}

@test "check_backup rechaza un artefacto alterado" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  printf 'alterado\n' >> "$RESPALDO/ops/Caddyfile"
  run python3 "$KIT/scripts/check_backup.py" "$RESPALDO"
  [ "$status" -eq 2 ]
}

@test "check_backup rechaza un .env en claro dentro del respaldo" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  cp "$KIT/.env" "$RESPALDO/.env"
  run python3 "$KIT/scripts/check_backup.py" "$RESPALDO"
  [ "$status" -eq 4 ]
}

@test "check_backup rechaza un respaldo no completado" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  python3 -c "import json,sys; p=sys.argv[1]; m=json.load(open(p)); m['status']='failed'; json.dump(m, open(p,'w'))" "$RESPALDO/manifest.json"
  run python3 "$KIT/scripts/check_backup.py" "$RESPALDO"
  [ "$status" -eq 2 ]
}

@test "restore en dry-run no escribe nada" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  export STUB_RUNNING=0
  run python3 "$KIT/scripts/restore.py" "$RESPALDO" "$KIT/destino" --dry-run
  [ "$status" -eq 0 ]
  [ ! -f "$RESPALDO/restore-report.json" ]
  [ ! -d "$KIT/logs" ]
}

@test "restore sin --confirmar no restaura" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  export STUB_RUNNING=0
  run python3 "$KIT/scripts/restore.py" "$RESPALDO" "$KIT/destino" 
  [ "$status" -eq 3 ]
  [ ! -f "$RESPALDO/restore-report.json" ]
}

@test "restore con --confirmar restaura y deja informe y auditoria" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  export STUB_RUNNING=0
  run python3 "$KIT/scripts/restore.py" "$RESPALDO" "$KIT/destino" --confirmar CONFIRMAR_RESTAURACION
  [ "$status" -eq 0 ]
  [ -f "$RESPALDO/restore-report.json" ]
  [ -f "$KIT/logs/restore.log" ]
  run grep -F "restore" "$KIT/logs/restore.log"
  [ "$status" -eq 0 ]
}

@test "restore aborta si el destino no esta vacio" {
  run python3 "$KIT/scripts/backup.py"
  [ "$status" -eq 0 ]
  RESPALDO="$(ls -d "$KIT"/backups/*/ | head -1)"
  export STUB_RUNNING=0
  export STUB_FIND_OUTPUT="dato-previo.txt"
  export STUB_PSQL_OUT=3
  mkdir -p "$KIT/destino"; printf "previo\n" > "$KIT/destino/previo.txt"
  run python3 "$KIT/scripts/restore.py" "$RESPALDO" "$KIT/destino" --confirmar CONFIRMAR_RESTAURACION
  [ "$status" -eq 5 ]
  [ ! -f "$RESPALDO/restore-report.json" ]
}
