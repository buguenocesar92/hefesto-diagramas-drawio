#!/usr/bin/env python3
"""Respaldo del kit hefesto-diagramas (draw.io).

Solo se respaldan archivos de configuracion: los diagramas viven en el
navegador del usuario (modo offline) y no hay backend que los guarde.

El .env nunca se copia en claro: al respaldo solo van sus nombres (env.vars) y,
si hay receptor age, el .env cifrado (env.age). El manifiesto lleva las cinco
claves del contrato. Ver docs/CONTRATO-RESPALDO.md.
"""
import datetime
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (escribir_manifiesto, ejecutar,  # noqa: E402
                               exportar_env, marcar_fallido)

SOFTWARE = 'hefesto-diagramas'
VERSION = '32.4.1'
DATABASE = 'ninguna'
CONFIG = ['compose.yaml', 'compose.bootstrap.yaml', 'ops/Caddyfile', 'ops/start.sh']


def main():
    root = Path(__file__).resolve().parents[1]
    os.umask(0o077)
    for n in CONFIG:
        if not (root / n).is_file():
            raise SystemExit('Falta archivo: ' + n)
    p = root / 'backups' / datetime.datetime.now(datetime.timezone.utc).strftime(
        '%Y%m%dT%H%M%S%fZ')
    p.mkdir(parents=True, mode=0o700)
    try:
        for n in CONFIG:
            dst = p / n
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(root / n, dst)
        meta = exportar_env(root, p)
        escribir_manifiesto(p, SOFTWARE, VERSION, DATABASE, extra=meta)
    except BaseException:
        marcar_fallido(p, SOFTWARE, VERSION, DATABASE)
        raise
    print('Configuracion respaldada en', p)
    print('El .env no viaja en claro: solo env.vars y, si hay receptor age, env.age.')
    print('No contiene datos del navegador: ningun diagrama queda respaldado.')
    return 0


if __name__ == '__main__':
    raise SystemExit(ejecutar(main))
