# Política de tratamiento de datos personales — Diagramas (draw.io) (Hefesto Studio)

Estado: vigente desde 2026-10-20. Responsable del tratamiento: el cliente que
opera el kit. Este documento describe qué datos guarda el kit, por qué, cuánto
tiempo los retiene y cómo se ejercen los derechos del titular (Ley 21.719).

## 1. Qué datos guarda este kit

El kit de diagramas (draw.io) guarda:

- **Configuración del kit**: `compose.yaml`, `compose.bootstrap.yaml`,
  `ops/Caddyfile`, `ops/start.sh` y la credencial de acceso (`BASIC_AUTH_HASH`),
  que nunca sale del servidor.
- **Copias locales de respaldo**: `backups/<timestamp>/` con la configuración
  anterior.

**Los diagramas no están en el servidor.** draw.io funciona en modo offline:
cada diagrama vive en el `localStorage`/`IndexedDB` del navegador de quien lo
dibujó. El kit no tiene backend de persistencia.

Esto es una decisión de privacidad favorable (nada sale del navegador), pero
tiene un coste operativo: **el "respaldo" de este kit no contiene ningún
diagrama**. Si el cliente necesita conservar los diagramas, la copia es la
exportación manual desde el navegador.

## 2. Qué datos NO guarda este kit

- El `.env` **no** se copia en claro al respaldo: solo sus nombres de variable
  (`env.vars`) y, si hay un receptor `age` configurado, el `.env` cifrado
  (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`, regla 5.
- El kit no guarda diagramas, ni los nombres de quienes los dibujan, ni ningún dato del navegador.

## 3. Base legal y deberes

- **Minimización**: el servidor guarda solo configuración. Los datos de personas que un diagrama pueda contener (nombres, correos, flujos de clientes) viven en el archivo exportado por el usuario, no en este kit.
- **Finalidad**: alojar un editor de diagramas accesible para el equipo del cliente. Los diagramas son responsabilidad de quien los dibuja y los exporta.
- **Seguridad**: los respaldos se cifran en reposo hacia el destino del
  operador, la clave privada no está en este servidor y el `.env` nunca sale
  en claro.
- **Auditoría**: cada respaldo y cada restauración dejan registro en
  `logs/restore.log` con origen, sha256 verificado, destino y resultado. Es
  registro de actividades de tratamiento: no guarda valores de secretos.

## 4. Retención

| Dato | Dónde | Retención por defecto | Quién lo borra |
|---|---|---|---|
| Configuración y credencial de acceso | `compose.yaml`, `ops/`, `.env` (nunca en el respaldo) | mientras el kit exista | el operador |
| Diagramas | navegador del usuario (localStorage/IndexedDB) | hasta que el usuario los exporta o borra | el usuario |
| Exportaciones manuales | donde el usuario las guarde | sin control por parte del kit | el usuario |
| Respaldos en disco | `backups/<timestamp>/` | **a definir por el operador**; el kit no borra nada por su cuenta | el operador |
| Registro de auditoría | `logs/restore.log` | append-only; se trunca por política del cliente | el operador |

**El kit no borra respaldos ni datos por su cuenta.** Borrar es una decisión del
operador, porque un respaldo borrado no se recupera.

## 5. Derechos del titular (acceso, rectificación y supresión)

1. **Acceso**: entregar los datos de un titular concreto desde la interfaz del
   kit o desde el dump de la base.
2. **Rectificación**: corregir los datos desde la interfaz del kit.
3. **Supresión**: eliminar el registro y dejar constancia de la supresión en el
   registro de auditoría.
4. **Revocación del consentimiento**: si el tratamiento depende del
   consentimiento, eliminar el registro.

El kit garantiza que los datos son localizables, corregibles y borrables; el
cliente es quien conoce la identidad de los titulares.

## 6. Verificación

- `bats tests/backup_restore.bats` comprueba, con datos sintéticos, que el
  `.env` no queda en claro, que el manifiesto lleva las cinco claves, que un
  artefacto alterado se rechaza y que un destino no vacío aborta la
  restauración.
- `gitleaks` corre en CI sobre el repositorio y su historial.
