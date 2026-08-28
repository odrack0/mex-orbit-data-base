# mex-orbit-data-base

El esquema de la base de datos y su historia completa: **toda alteración a la BD nace aquí, versionada, con su reversa.**

> **MexOrbit** es nombre temporal del proyecto. Documentación en español; **esquema en inglés, comentarios SQL en español**.

## Decisiones tomadas

- **Motor: MySQL.** La mejora estructural es el esquema y la disciplina — no el motor.
- **UNA sola base de datos** compartida por `mex-orbit-game-server` y `mex-orbit-api` (la frontera es de *escritura por dominio*: la simulación escribe lo suyo, la plataforma lo suyo — se documenta por tabla).
- **El esquema se diseña desde cero**: NPCs separados de naves de jugador, cero JSON-en-varchar para datos estructurados, claves foráneas reales, nombres en inglés. La BD `darkorbit` legada es referencia de dominio, no punto de partida.

## Convención de versionado

Cada cambio es una carpeta fechada con consecutivo del día, siempre con **rollout y rollback**:

```
2026.08.24.1/
  rollout.sql     -- aplica el cambio
  rollback.sql    -- lo revierte exactamente
2026.08.24.2/
  rollout.sql
  rollback.sql
```

Reglas:
1. **Ningún cambio a la BD sin su carpeta** — ni "un ALTER rapidito" en producción. La carpeta ES el cambio.
2. **El rollback se escribe junto con el rollout**, no cuando duele.
3. Los scripts son **idempotentes** donde sea posible (`IF NOT EXISTS`, `ON DUPLICATE KEY`).
4. Cada carpeta lleva al inicio del `rollout.sql` un comentario: qué cambia, por qué, y qué repos/versiones lo requieren.
5. Los datos semilla del juego (catálogo de items, NPCs, mapas, recetas — los números del guideline) también entran por aquí, como migraciones de datos.

## Qué NO es

- No es un dump: nada de baselines binarios como método de despliegue (la lección de los `darkorbit_baseline_*.sql` del legado). El estado actual de la BD = la suma ordenada de las migraciones.
- No contiene lógica de acceso (eso vive en cada servicio); aquí vive la **estructura y su historia**.

## Relación con otros repos

| Repo | Relación |
|---|---|
| `mex-orbit-game-server` / `mex-orbit-api` | Consumidores del esquema; sus despliegues declaran qué versión de migración requieren |
| `mex-orbit-docs` | El pilar 02-base-de-datos define el esquema; aquí se ejecuta |

## Migraciones aplicadas

| Versión | Qué trae |
|---|---|
| `2026.08.25.1` | Estructura núcleo del vertical slice + semilla del catálogo (items, naves, NPCs, mapa 1-1, recetas, precios) |
| `2026.08.25.2` | Stats jugables del Vex (800/400): el seed original daba un TTK de >3 min con el ION-1 |
| `2026.08.25.3` | El portal del 1-1 + el mapa vecino `1-2` que exige su FK. `map_portal.target_map_id` es FK real, así que **crear un portal implica crear su destino**: `1-2` queda declarado sin estación ni spawns, y el salto llega en E3 |
| `2026.08.25.4` | Vexor y Skarn en el 1-1: el bestiario pasa a tres (15 Vex, 8 Vexor, 5 Skarn). Stats derivados del TTK con el ION-1 del arranque |
| `2026.08.25.5` | Ferox y Skarnox: el bestiario del 1-1 llega a cinco (15/8/5/4/2). Escalera de TTK 10 · 20 · 27 · 33 · 47 s. **Deuda anotada**: 47 s es largo porque el ION-1 es el único láser del catálogo — la cima pide una segunda grada de láser, no bichos más flojos |
| `2026.08.25.6` | Enciende `is_aggressive` en el Ferox (el único cazador del 1-1) y añade `CARGO_LOST` al ledger, para asentar la bodega que se queda flotando al morir |
| `2026.08.25.7` | Primera calibración del daño de los NPCs (25–75). Los valores previos nunca se probaron contra un jugador: al encender la IA, el autotest moría en ~15 s contra un solo Ferox |
| `2026.08.25.8` | Bodega de la Phoenix 100 → 300. Con 100 te llenabas cada dos Vex y las cajas del Ferox/Skarnox ni cabían: el sobrante se evaporaba al expirar la caja, y los materiales solo salen de esas cajas |
| `2026.08.25.9` | Gravit y Mordax: el bestiario del 1-1 llega a siete (48 bichos). Ninguno sube el techo del mapa — caen dentro de la banda existente (15 s y 30 s de TTK) |
| `2026.08.25.10` | Gravon y Vorax: nueve especies en el 1-1 (54 bichos) + columna `flee_hp_pct`. El Vorax huye por debajo del 30% de casco — primer NPC con conducta, no solo estadísticas |
| `2026.08.25.11` | Interruptor `npc_combat_enabled` en `server_setting`, **apagado** por ahora: los NPC vagabundean, fichan y persiguen, pero no hacen daño |
| `2026.08.26.1` | El sistema estelar: 29 mapas y 42 puertas (84 portales), extraidos del arte del mapa estelar y validados por el recuento J1..J42 y la simetria de las tres facciones |
| `2026.08.26.2` | La llegada del salto pasa a ser la posicion EXACTA del portal de vuelta, y `map_server` dice donde vive cada mapa (hoy todos al mismo sitio; partirlos manana es cambiar filas) |
| `2026.08.28.1` | Diales de la **relevancia por rango**: `render_range_entities` (2000), `render_range_objects` (1250) y `render_range_hysteresis_pct` (10). El cliente deja de recibir el sector entero |
| `2026.08.28.2` | Se **enciende** `npc_combat_enabled` y el daño de todas las especies baja a **10**. Los 25-85 se calibraron contra un jugador al que no se podia perseguir; con la persecucion arreglada, la dificultad esta sin medir y 10 es el suelo plano desde el que calibrar |

Correr una versión contra el MySQL de dev:

```bash
.\tools\migrate.ps1 -Version 2026.08.25.3
```

## Estado

Esquema núcleo del vertical slice en pie y en uso por `mex-orbit-api` y `mex-orbit-game-server`.

## Despliegue

Producción usa la base `astrion` en el MySQL del servidor (3306, no el 3307 de dev) con un usuario
propio, `astrion`. Nunca `root`: es el mismo patrón que ya seguía el prototipo.

Los tres comandos se corren **en el servidor**, sobre el clon de
`/home/astrion/mex-orbit-v1/mex-orbit-data-base`. MySQL solo escucha en `127.0.0.1` y así debe
seguir, así que no hay forma de correrlos desde el PC sin un túnel — y correrlos aquí sin `DB=`
apuntaría a la base de dev, que es exactamente el accidente que esta nota evita.

```bash
ssh root@74.208.108.67
cd /home/astrion/mex-orbit-v1/mex-orbit-data-base
git pull

DB=astrion ./tools/migrate.sh --estado     # qué falta, sin tocar nada
DB=astrion ./tools/migrate.sh              # aplica todas las pendientes, en orden
mysql astrion < deploy/produccion.sql      # y SIEMPRE esto después
```

`migrate.ps1` sigue existiendo para dev y aplica **una** versión; `migrate.sh` aplica **todas las
pendientes**, y esa es la razón de que exista: en producción nadie va a teclear treinta versiones a
mano sin saltarse una. El orden sale del nombre de la carpeta con `sort -V`, no con un `sort`
normal — ya hay una `2026.08.25.10`, y un `sort` normal la pondría antes que la `.2`.

### `deploy/produccion.sql` no es opcional

Lleva lo que depende de la **máquina** y no del esquema. Hoy es `map_server`: la migración lo siembra
en `127.0.0.1:5200` sin TLS, que es correcto en dev y **una bomba en producción**. El host del salto
de sector sale de esa tabla, no del que usó el cliente para entrar, así que el juego entraría bien y
fallaría justo al cambiar de mapa.

Es el fallo más caro de diagnosticar de todo el despliegue, porque no aparece hasta el segundo mapa
y todo lo demás funciona. Por eso el script termina contando cuántas filas siguen apuntando a dev:
la respuesta correcta es cero.

Es idempotente, y hay que correrlo **después de cada migración que toque `map` o `map_server`**.
