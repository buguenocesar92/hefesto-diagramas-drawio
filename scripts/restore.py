#!/usr/bin/env python3
"""Restauracion de la configuracion de hefesto-diagramas en un destino nuevo.

Sin --confirmar CONFIRMAR_RESTAURACION no se escribe nada; con --dry-run se
simula. Valida el manifiesto y los sha256 antes de tocar el destino, exige un
destino vacio y deja restore-report.json y auditoria.

El .env NO viaja en el respaldo: el destino debe conservar el suyo (credencial
de acceso). El respaldo solo deja los nombres de variable (env.vars) y, si hay
receptor age, el .env cifrado (env.age).
"""
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (RespaldoError, auditar, ejecutar,  # noqa: E402
                               ejecutar_check, escribir_informe, opciones_restore)

SOFTWARE = 'hefesto-diagramas'
VERSION = '32.4.1'
DATABASE = 'ninguna'
CONFIG = ['compose.yaml', 'compose.bootstrap.yaml', 'ops/Caddyfile', 'ops/start.sh']


def main():
    modo, origen, destino = opciones_restore(sys.argv[1:], con_destino=True)
    origen = Path(origen).resolve()
    destino = Path(destino).resolve() if destino else Path(__file__).resolve().parents[1]
    ejecutar_check(str(origen), SOFTWARE, VERSION, DATABASE)
    if modo == 'dry-run':
        print('Simulacion: el respaldo es integro y no se escribio nada.')
        print('Para restaurar de verdad: --confirmar CONFIRMAR_RESTAURACION')
        return 0
    if destino.exists() and any(destino.iterdir()):
        raise RespaldoError('Destino no vacio; no se sobrescribe', 5)
    destino.mkdir(parents=True, exist_ok=True, mode=0o700)
    for n in CONFIG:
        d = destino / n
        d.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(origen / n, d)
    escribir_informe(origen, software=SOFTWARE, version=VERSION, database=DATABASE,
                     modo='confirmado', resultado='restaurado', destino=str(destino))
    auditar(Path(__file__).resolve().parents[1], operacion='restore', kit=SOFTWARE,
            origen=str(origen), destino=str(destino), resultado='restaurado')
    print('Configuracion restaurada. Revisar y arrancar primero por tunel privado.')
    return 0


if __name__ == '__main__':
    raise SystemExit(ejecutar(main))
