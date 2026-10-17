#!/usr/bin/env python3
import hashlib,json,os,shutil,sys
from pathlib import Path
if len(sys.argv)!=3:raise SystemExit('Uso: python3 scripts/restore.py /ruta/respaldo /ruta/destino-nuevo')
src=Path(sys.argv[1]).resolve();dst=Path(sys.argv[2]).resolve();os.umask(0o077)
m=json.loads((src/'manifest.json').read_text())
if (m.get('product'),m.get('version'),m.get('status'))!=('hefesto-diagramas','32.4.1','completed'):raise SystemExit('Manifest incorrecto')
files=['.env','compose.yaml','compose.bootstrap.yaml','ops/Caddyfile','ops/start.sh']
if set(m.get('sha256',{}))!=set(files):raise SystemExit('Lista de archivos inesperada')
for n in files:
 p=src/n
 if p.is_symlink() or not p.is_file() or src not in p.resolve().parents:raise SystemExit('Ruta no admitida')
 if hashlib.sha256(p.read_bytes()).hexdigest()!=m['sha256'][n]:raise SystemExit('Checksum incorrecto')
if dst.exists() and any(dst.iterdir()):raise SystemExit('Destino no vacío; no se sobrescribe')
dst.mkdir(parents=True,exist_ok=True,mode=0o700)
for n in files:
 p=dst/n;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src/n,p)
os.chmod(dst/'.env',0o600)
print('Configuración restaurada. Revisar y arrancar primero por túnel privado.')
