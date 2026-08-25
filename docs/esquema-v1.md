# Esquema BD v1 — diseño (E1)

**Estado: borrador para revisión** (2026-08-25). Pilar rector: [02-base-de-datos](https://github.com/odrack0/mex-orbit-docs/blob/main/04-pilares/02-base-de-datos.md). La migración inicial vive en [`migrations/2026.08.25.1/`](../migrations/2026.08.25.1/).

Alcance: los dominios del **vertical slice E2** (*login → conectar → volar → matar un Vex → recoger carga → volver a base → refinado automático → almacén → vender al NPC*) más los cimientos que serían caros de añadir después. Los dominios E3+ se listan al final sin tablas.

## 0. La lista negra del legado (lo que este esquema hace imposible)

Del análisis del baseline legado (40 tablas, bicapa moderna/emulador):

| Pecado | Respuesta en v1 |
|---|---|
| Credits/honor/EXP dentro de un JSON string (`player_accounts.data`) | La cartera son filas de `player_resource_balance` — sumable, indexable, transaccionable |
| Posesión de items como claves ad-hoc de JSON de 1000 bytes (`player_equipment.items`) | `player_item`: **una fila = una unidad**, con FK y durabilidad |
| NPCs y naves de jugador en la misma tabla (`server_ships`), con `cargo` significando dos cosas | `ship_catalog` y `npc_catalog` separados; cada columna un solo significado |
| Contenido del mundo como JSON sin FK (`server_maps.npcs/portals`) | `map_portal`, `map_station`, `map_npc_spawn` con FKs reales |
| `userId` con dos anchos (`int` vs `bigint`) → FKs imposibles | **`BIGINT UNSIGNED` único** para todo id de cuenta; FK en cada tabla hija |
| Charset partido (`utf8_bin` case-sensitive vs `utf8mb4`) | `utf8mb4` + `utf8mb4_0900_ai_ci` en todo; usernames case-insensitive por colación |
| Estado de simulación en la fila de cuenta (`current_hit_points` que congelaba el server) | `player_ship_state`: tabla propia, un solo escritor, write-behind |
| Adornos y tier dentro del nombre (`-=[ Streuner ]=-`) | `display_name` limpio + `species` + `threat_tier` como columnas |
| Recompensas y drops hardcodeados en C# (`Randoms.random.Next(...)`) | `npc_catalog.reward_*`, `zone_drop_bias`, `refine_recipe`: **dato, no código** |
| Límites de mapa en un `if` (`ParseLimits()`) | `map.bounds_max_x/y` |
| `server_settings` sin tipo, rango ni auditoría | `server_setting` tipado con min/max/unidad + `server_setting_audit` |
| Sin `created_at/updated_at`, sin tabla de sesiones, dos algoritmos de password | Timestamps en todo; `api_session`/`game_session`; Argon2id único |

## 1. Convenciones

- MySQL 8, InnoDB, `utf8mb4` / `utf8mb4_0900_ai_ci` en toda la BD.
- Esquema en **inglés**, comentarios en **español** (`COMMENT` en cada tabla y columna no obvia).
- Ids `BIGINT UNSIGNED AUTO_INCREMENT`; FKs reales en toda relación; `created_at`/`updated_at` en toda tabla mutable.
- Nombres de tabla en singular. Nada de JSON para datos estructurados (excepción única y justificada: ninguna en v1).
- Todo cambio entra por migración `AAAA.MM.DD.N/rollout.sql + rollback.sql`; el runner registra en `schema_migration`.

## 2. Dominios y tablas del slice

### 2.1 Cuentas y sesiones (escribe: api)

- **`account`** — id, `username` (UNIQUE, case-insensitive), `email`, `password_hash` (Argon2id), `pilot_name` (UNIQUE), `faction_id`, `status` (ACTIVE/BANNED/LOCKED), timestamps. Sin monedas aquí: la cartera vive en `player_resource_balance`.
- **`api_session`** — token opaco (solo `token_hash`), expiración deslizante, revocación. La api emite y valida.
- **`game_session`** — la emite el game server al aceptar `Hello`; sesión única por cuenta (índice único parcial sobre las vivas), `reconnect_token_hash`, `last_seen_at`, `close_reason`. El árbitro del predicado "conectado" para la frontera de escritura (§4).
- **`login_audit`** — append-only: intento, IP, resultado.

### 2.2 Catálogo de items (escribe: migraciones / api-admin)

Herencia directa del modelo ya diseñado en el legado (`server_item*` — la parte del legado que estaba bien):

- **`server_item_category`** — `material`, `currency`, `laser`, `generator`, … 
- **`server_item`** — `item_key`, `loot_id` (UNIQUE, el id que viaja por el protocolo y nombra el arte), `category_id`, `is_wallet_balance` (credits y materiales = saldo; láseres = instancias), `max_owned`.
- **`server_item_stat_type`** / **`server_item_stat`** — stats del catálogo (daño del ION-1, escudo del NAN-1).
- **Precios fuera del catálogo**: `npc_sell_price` (y en E3 `npc_shop_price`) — un precio es un dial de balanceo con historial, no una propiedad del item.

### 2.3 Items del jugador y equipo (escribe: api; durabilidad: game server)

- **`player_item`** — **una fila = una unidad**: `account_id`, `server_item_id`, `level`, `origin`, `bound`, **`durability_current` / `durability_max`** — la columna nace en E2 aunque el desgaste llegue en E3: los guidelines condicionan comerciar y revender a "reparación completa"; es invariante del modelo, no feature.
- **`player_item_stat`** — overrides por instancia.
- **`player_equipment_slot`** — `account_id`, `ship_config` (1|2), `slot_kind` (laser/generator/heavy_gun/extra), `sort_order`, `player_item_id`. (Drones y su bahía: E3+, se modelará como `player_drone_bay` — decidido, no improvisado en la UNIQUE como hizo el legado.)

### 2.4 Naves (catálogo: migraciones · posesión: api · estado: game server)

- **`ship_catalog`** — `code` (phoenix…), `display_name`, `tier`, `role`, `base_hp/base_shield/base_speed`, `laser_slots/generator_slots/heavy_gun_slots/extra_slots`, `cargo_capacity`. Solo naves de jugador. Valores §11 de guidelines (provisionales hasta la pasada de balanceo).
- **`player_ship`** — posesión: `account_id`, `ship_catalog_id`, `is_active`.
- **`player_ship_state`** — **la única tabla caliente**: `account_id` PK, `map_id`, `pos_x/pos_y`, `current_hp`, `current_shield`, `is_destroyed`, `updated_at`. Un solo escritor (game server), write-behind al descargar/logout/evento clave. Regla de negocio: `current_hp = 0` al login se resuelve con respawn gratis en base — **jamás con bloqueo** (la lección del TickManager congelado).

### 2.5 Mundo (escribe: migraciones / api-admin)

- **`map`** — `code` ("1-1"), `display_name`, `faction_id`, **`bounds_max_x/bounds_max_y`**, **`zone_tier`** (LOW/MID/HIGH — el eje del sesgo de drops y del gradiente de muerte), `is_starter`, `is_pvp`.
- **`map_portal`** — posición + **`target_map_id` FK real** + posición destino (el protocolo v1 sí transmite el destino).
- **`map_station`** — `station_type` (HOME_BASE…), `faction_id`, posición, `secure_range`.
- **`npc_catalog`** — `code` (vex), `display_name` limpio, `species`, `threat_tier` (BASE/ELITE/TITAN/IMPERATOR), `max_hp/max_shield/speed/damage`, `is_aggressive`, `respawn_seconds`, `aggro_radius`, `reward_experience/reward_honor/reward_credits`, `cargo_drop_min/cargo_drop_max` (unidades totales de material que suelta su caja).
- **`map_npc_spawn`** — `map_id` FK, `npc_catalog_id` FK, `amount`.
- **`zone_drop_bias`** — `zone_tier`, `server_item_id`, `weight`: la **mezcla** de materiales la fija la zona (60/30/10 · 30/45/25 · 15/30/55), el NPC aporta la cantidad. Invariante a validar por la consola: ninguna zona replica la mezcla implícita de la receta (50/33/17).

### 2.6 Materiales y economía del slice

La separación más importante del modelo (sin ella, el gradiente de muerte 0/50/100 de E3 es inimplementable):

- **`player_cargo_hold`** (escribe: **game server, exclusivo**) — la **bodega volante**, lo único en riesgo: `account_id`, `server_item_id`, `amount`. Tope = `ship_catalog.cargo_capacity`. Se vacía al descargar en base (o al morir, E3).
- **`player_resource_balance`** (escribe: **ambos**, ver §4) — el **almacén global** + cartera: `account_id`, `server_item_id` (solo `is_wallet_balance=1`), `amount DECIMAL(20,6)`. Único por jugador, accesible desde cualquier base; jamás en riesgo. Capacidad: sin límite en v1 (el guideline lo deja por definir; el gancho existe, el número no).
- **`refine_recipe`** / **`refine_recipe_ingredient`** — 30 Asterium + 20 Nebulium + 10 Coronium → 1 Aurorium, **como dato**. Se ejecuta automática y gratis al descargar en base; sin colas ni timers.
- **`npc_sell_price`** — Asterium 10 C · Nebulium 15 C · Coronium 25 C (provisional).
- **`economy_ledger`** (append-only, escriben ambos) — `account_id`, `server_item_id`, `delta`, `reason` (NPC_KILL/CARGO_PICKUP/REFINE_IN/REFINE_OUT/NPC_SALE/…), `ref_id`, `occurred_at`. **El invariante de convergencia se demuestra con este registro, no con fe** — imposible de reconstruir retroactivamente, barato de escribir desde el día uno.

### 2.7 Configuración calibrable (escribe: api-admin, con auditoría)

- **`server_setting`** — `setting_key`, `value`, **`value_type`, `min_value`, `max_value`, `unit`, `description`**. Para escalares sueltos (retardo de portal 3250 ms, gracia de reconexión 60 s, rango seguro de base 1500…).
- **`server_setting_audit`** — quién cambió qué número y cuándo. Los diales estructurados (sesgos, precios, recetas) ya son tablas tipadas propias; los defaults entran por migración de datos.

## 3. Diagrama de dependencias (resumen)

```
account ──┬── api_session / game_session / login_audit
          ├── player_item ──── player_item_stat
          │       └── player_equipment_slot
          ├── player_ship ──── ship_catalog
          ├── player_ship_state ──── map
          ├── player_cargo_hold ──┐
          └── player_resource_balance ──┴── server_item ── server_item_category
                                                  ├── server_item_stat
                                                  ├── zone_drop_bias
                                                  ├── refine_recipe_ingredient ── refine_recipe
                                                  └── npc_sell_price
map ──┬── map_portal (target_map_id FK) ── map_station ── map_npc_spawn ── npc_catalog
economy_ledger (append-only) · server_setting + audit · schema_migration
```

## 4. Frontera de escritura (tabla por tabla)

| Tabla | Escritor | Nota |
|---|---|---|
| `account`, `api_session`, `login_audit` | api | identidad |
| `game_session` | game server | la api solo lee |
| catálogos (`server_item*`, `ship_catalog`, `map*`, `npc_catalog`, `zone_drop_bias`, `refine_recipe*`, `npc_sell_price`) | migraciones / api-admin | nadie en runtime |
| `player_item` (crear/destruir), `player_equipment_slot`, `player_ship` | api | actos de hangar/plataforma |
| `player_item.durability_*` (desgaste y reparación) | game server | ocurre en la simulación, en la estación |
| `player_ship_state`, `player_cargo_hold` | **game server exclusivo** | estado de simulación |
| `player_resource_balance` | **ambos, bajo la regla de abajo** | el punto caliente |
| `economy_ledger`, `server_setting_audit` | ambos / api-admin | append-only, sin UPDATE ni DELETE |

**La regla del almacén** (resuelve la pregunta abierta del pilar 04-api): *el game server escribe `player_resource_balance` mientras el jugador está conectado (descargar, refinar, vender al NPC son actos físicos en la estación, dentro del tick); la api escribe cuando no lo está (Mercado E3, operaciones offline). `game_session` es el árbitro del predicado.* Dos salvaguardas obligatorias: (1) **escrituras siempre relativas** (`SET amount = amount + :delta` condicionado, nunca valores absolutos leídos antes); (2) cuando en E3 el Mercado deba abonar a un jugador conectado: encola el evento hacia el game server o toma lock de fila — nunca dos escritores concurrentes sobre la misma cuenta.

## 5. Persistencia del estado en vivo

- `player_ship_state` y `player_cargo_hold` se escriben **write-behind**: al descargar en base, al logout/desconexión, al morir, y como máximo cada 30 s si hay cambios (dial en `server_setting`).
- El resto de la simulación (posición fina, cooldowns, cajas `from_ship`) vive en memoria del game server y se pierde sin culpa en un reinicio. La Black Box (E3) sí se persistirá: es transferencia de valor entre jugadores.

## 6. Migración `2026.08.25.1`

- `rollout.sql`: crea `schema_migration` + las 25 tablas del slice + semillas (categorías, credits + 4 materiales, ION-1/NAN-1, Phoenix, mapa 1-1 con base y portal de práctica, Vex con spawn ×15, sesgos de zona, receta, precios NPC, settings). Todos los números marcados **provisionales** hasta la pasada de balanceo (E6).
- `rollback.sql`: revierte todo en orden inverso de dependencias, incluida su fila de `schema_migration`.

### Corrida de verificación (I3) — ✅ 2026-08-25

Contra **MySQL 8.4.11 LTS** limpio (dev local): rollout → **29 tablas** creadas, semillas verificadas
(7 items de catálogo, 9 sesgos de zona, 3 ingredientes de receta, versión registrada) → rollback → **0 tablas,
sin residuos** → rollout de nuevo → 29 tablas y semillas íntegras. **La migración es aplicable y reversible.**

### El MySQL de desarrollo local

La máquina de dev tiene una MariaDB 10.1 legada en el puerto 3306 (el prototipo); **no se toca**. El motor de
v1 corre aparte, portable y sin servicio:

- Instalación: ZIP oficial `mysql-8.4.11-winx64` extraído en `C:\Tools\mysql8` (sin instalador, sin servicio).
- Arranque/apagado: [`tools/dev-mysql.ps1`](../tools/dev-mysql.ps1) (puerto **3307**, root sin contraseña —
  solo dev local; el datadir se inicializa solo la primera vez).
- Migraciones: [`tools/migrate.ps1`](../tools/migrate.ps1) `-Version AAAA.MM.DD.N [-Rollback]` sobre la BD
  `mexorbit_dev`. Es el runner mínimo de E1; el definitivo (aplicación ordenada de N versiones, verificación
  del registro) llega con E2.

## 7. Dominios futuros (E3+, sin tablas en v1)

Mercado de órdenes · muerte completa (gradiente por zona, Black Box, desgaste) · pods y Flux · tienda NPC T0–T3 · misiones · Eclipses/Materializador · recubrimientos · AMPs y partículas · perfil del piloto (25 skills en tablas, no JSON) · world bosses/Tachyon · planos y pity · incursiones · Arena · eventos de defensa · clanes (membresía en tablas, no JSON) · temporadas y rangos · Starbond/License · cosméticos · P.E.T.

Cada uno llega **agregando tablas y migraciones**, nunca redefiniendo las del slice — las tres decisiones estructurales de arriba (bodega/almacén separados, estado de nave propio, durabilidad desde el día uno) existen precisamente para eso.
