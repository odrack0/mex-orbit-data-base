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

Correr una versión contra el MySQL de dev:

```bash
.\tools\migrate.ps1 -Version 2026.08.25.3
```

## Estado

Esquema núcleo del vertical slice en pie y en uso por `mex-orbit-api` y `mex-orbit-game-server`.
