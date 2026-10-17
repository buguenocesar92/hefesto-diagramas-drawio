#!/usr/bin/env python3
import datetime,hashlib,json,os,shutil
from pathlib import Path
r=Path(__file__).resolve().parents[1];os.umask(0o077)
files=['.env','compose.yaml','compose.bootstrap.yaml','ops/Caddyfile','ops/start.sh']
for n in files:
    if not (r/n).is_file():raise SystemExit('Falta archivo: '+n)
p=r/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');p.mkdir(parents=True,mode=0o700)
hashes={}
for n in files:
    dst=p/n;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/n,dst)
    hashes[n]=hashlib.sha256(dst.read_bytes()).hexdigest()
(p/'manifest.json').write_text(json.dumps({'product':'hefesto-diagramas','version':'32.4.1','status':'completed','sha256':hashes},indent=2))
print('Configuración respaldada en',p,'No contiene datos del navegador.')
