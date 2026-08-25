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

## Estado

Repo recién creado. Primer paso: el documento de diseño del esquema (pilar) → la migración `.1` inicial (estructura núcleo del vertical slice).
