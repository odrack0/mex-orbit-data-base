-- ============================================================
-- Migración 2026.08.25.1 — esquema inicial del vertical slice (E1/E2)
-- Diseño: docs/esquema-v1.md. Todos los números de juego son
-- provisionales hasta la pasada de balanceo (E6).
-- Requiere: MySQL 8.0+, base de datos vacía o sin estas tablas.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- ---------- registro del runner de migraciones ----------
CREATE TABLE IF NOT EXISTS schema_migration (
  version     VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT 'AAAA.MM.DD.N',
  applied_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'cuándo se aplicó el rollout'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='migraciones aplicadas, en orden';

-- ============================================================
-- 1. CUENTAS Y SESIONES (escribe: api; game_session: game server)
-- ============================================================

CREATE TABLE account (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(32)  NOT NULL COMMENT 'login; único e insensible a mayúsculas por colación',
  email         VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL COMMENT 'Argon2id, un solo algoritmo en toda la BD',
  pilot_name    VARCHAR(32)  NOT NULL COMMENT 'nombre visible en el juego, separado del login',
  faction_id    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  status        ENUM('ACTIVE','BANNED','LOCKED') NOT NULL DEFAULT 'ACTIVE',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_account_username (username),
  UNIQUE KEY uk_account_pilot_name (pilot_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='cuentas; la cartera vive en player_resource_balance, nunca aquí';

CREATE TABLE api_session (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id  BIGINT UNSIGNED NOT NULL,
  token_hash  CHAR(64) NOT NULL COMMENT 'SHA-256 del token opaco; el token en claro jamás se guarda',
  issued_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at  TIMESTAMP NOT NULL COMMENT 'expiración deslizante (7 días)',
  revoked_at  TIMESTAMP NULL DEFAULT NULL,
  last_seen_at TIMESTAMP NULL DEFAULT NULL,
  ip          VARCHAR(45) NULL,
  UNIQUE KEY uk_api_session_token (token_hash),
  KEY ix_api_session_account (account_id),
  CONSTRAINT fk_api_session_account FOREIGN KEY (account_id) REFERENCES account(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='sesiones REST emitidas por la api';

CREATE TABLE game_session (
  id                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id           BIGINT UNSIGNED NOT NULL,
  connected_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reconnect_token_hash CHAR(64) NOT NULL,
  closed_at            TIMESTAMP NULL DEFAULT NULL,
  close_reason         ENUM('LOGOUT','REPLACED','TIMEOUT','KICKED','SHUTDOWN') NULL,
  -- sesión única por cuenta: solo una fila viva (closed_at NULL) por cuenta;
  -- se materializa con la columna generada de abajo
  live_account_id BIGINT UNSIGNED AS (IF(closed_at IS NULL, account_id, NULL)) STORED
    COMMENT 'NULL al cerrar; el UNIQUE de abajo garantiza una sola sesión viva por cuenta',
  UNIQUE KEY uk_game_session_live (live_account_id),
  KEY ix_game_session_account (account_id),
  CONSTRAINT fk_game_session_account FOREIGN KEY (account_id) REFERENCES account(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='sesiones de juego; el árbitro del predicado "conectado" de la frontera de escritura';

CREATE TABLE login_audit (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id        BIGINT UNSIGNED NULL COMMENT 'NULL si el usuario no existe',
  username_attempt  VARCHAR(64) NOT NULL,
  ip                VARCHAR(45) NULL,
  result            ENUM('OK','BAD_CREDENTIALS','LOCKED','BANNED','RATE_LIMITED') NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_login_audit_account (account_id),
  KEY ix_login_audit_created (created_at),
  CONSTRAINT fk_login_audit_account FOREIGN KEY (account_id) REFERENCES account(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='append-only: materia prima de la consola de moderación';

-- ============================================================
-- 2. CATÁLOGO DE ITEMS (escribe: migraciones / api-admin)
-- ============================================================

CREATE TABLE server_item_category (
  id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL COMMENT 'material, currency, laser, generator, ...',
  UNIQUE KEY uk_item_category_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='categorías del catálogo';

CREATE TABLE server_item (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  item_key          VARCHAR(64)  NOT NULL COMMENT 'clave interna estable',
  loot_id           VARCHAR(191) NOT NULL COMMENT 'id público: viaja por el protocolo y nombra el arte',
  category_id       BIGINT UNSIGNED NOT NULL,
  display_name      VARCHAR(64)  NOT NULL,
  is_wallet_balance TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '1 = saldo (credits/materiales); 0 = instancia (player_item)',
  max_owned         INT UNSIGNED NULL COMMENT 'tope de posesión; NULL = sin tope',
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_server_item_key (item_key),
  UNIQUE KEY uk_server_item_loot (loot_id),
  CONSTRAINT fk_server_item_category FOREIGN KEY (category_id) REFERENCES server_item_category(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='catálogo de items; los precios viven en tablas de calibración, no aquí';

CREATE TABLE server_item_stat_type (
  id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL COMMENT 'damage, shield, speed_bonus, ...',
  unit VARCHAR(16) NULL,
  UNIQUE KEY uk_stat_type_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='tipos de stat del catálogo';

CREATE TABLE server_item_stat (
  server_item_id BIGINT UNSIGNED NOT NULL,
  stat_type_id   BIGINT UNSIGNED NOT NULL,
  value          DECIMAL(20,6) NOT NULL,
  PRIMARY KEY (server_item_id, stat_type_id),
  CONSTRAINT fk_item_stat_item FOREIGN KEY (server_item_id) REFERENCES server_item(id),
  CONSTRAINT fk_item_stat_type FOREIGN KEY (stat_type_id) REFERENCES server_item_stat_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='stats base por item de catálogo';

-- ============================================================
-- 3. ITEMS DEL JUGADOR Y EQUIPO (escribe: api; durabilidad: game server)
-- ============================================================

CREATE TABLE player_item (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id         BIGINT UNSIGNED NOT NULL,
  server_item_id     BIGINT UNSIGNED NOT NULL,
  level              SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  origin             ENUM('SEED','SHOP','DROP','CRAFT','TRADE','REWARD') NOT NULL DEFAULT 'SEED',
  bound              TINYINT(1) NOT NULL DEFAULT 0,
  durability_current DECIMAL(7,4) NOT NULL DEFAULT 100.0 COMMENT 'porcentaje; el desgaste llega en E3, la columna nace hoy',
  durability_max     DECIMAL(7,4) NOT NULL DEFAULT 100.0,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY ix_player_item_account (account_id),
  CONSTRAINT fk_player_item_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_player_item_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='una fila = una unidad física de item; los usados se comercian con su durabilidad';

CREATE TABLE player_item_stat (
  player_item_id BIGINT UNSIGNED NOT NULL,
  stat_type_id   BIGINT UNSIGNED NOT NULL,
  value          DECIMAL(20,6) NOT NULL,
  PRIMARY KEY (player_item_id, stat_type_id),
  CONSTRAINT fk_pistat_item FOREIGN KEY (player_item_id) REFERENCES player_item(id),
  CONSTRAINT fk_pistat_type FOREIGN KEY (stat_type_id) REFERENCES server_item_stat_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='overrides de stat por instancia (potenciación)';

CREATE TABLE player_equipment_slot (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id     BIGINT UNSIGNED NOT NULL,
  ship_config    TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1 o 2',
  slot_kind      ENUM('LASER','GENERATOR','HEAVY_GUN','EXTRA') NOT NULL,
  sort_order     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  player_item_id BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY uk_equipment_slot (account_id, ship_config, slot_kind, sort_order),
  UNIQUE KEY uk_equipment_item_per_config (player_item_id, ship_config),
  CONSTRAINT fk_equip_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_equip_item FOREIGN KEY (player_item_id) REFERENCES player_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='equipo por configuración; drones llegan en E3 con su propia tabla de bahía';

-- ============================================================
-- 4. NAVES (catálogo: migraciones · posesión: api · estado: game server)
-- ============================================================

CREATE TABLE ship_catalog (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code            VARCHAR(32) NOT NULL,
  display_name    VARCHAR(64) NOT NULL,
  tier            ENUM('STARTER','LOW','ROLE','HIGH') NOT NULL,
  role            VARCHAR(32) NULL COMMENT 'NULL para naves de línea',
  base_hp         INT UNSIGNED NOT NULL,
  base_shield     INT UNSIGNED NOT NULL DEFAULT 0,
  base_speed      SMALLINT UNSIGNED NOT NULL,
  laser_slots     TINYINT UNSIGNED NOT NULL,
  generator_slots TINYINT UNSIGNED NOT NULL,
  heavy_gun_slots TINYINT UNSIGNED NOT NULL DEFAULT 0,
  extra_slots     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  cargo_capacity  INT UNSIGNED NOT NULL,
  UNIQUE KEY uk_ship_catalog_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='solo naves de jugador; los NPC viven en npc_catalog';

CREATE TABLE player_ship (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id      BIGINT UNSIGNED NOT NULL,
  ship_catalog_id BIGINT UNSIGNED NOT NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  acquired_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_player_ship_account (account_id),
  CONSTRAINT fk_player_ship_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_player_ship_catalog FOREIGN KEY (ship_catalog_id) REFERENCES ship_catalog(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='posesión de naves';

-- ============================================================
-- 5. MUNDO (escribe: migraciones / api-admin)
-- ============================================================

CREATE TABLE map (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code         VARCHAR(16) NOT NULL COMMENT 'p. ej. 1-1',
  display_name VARCHAR(64) NOT NULL,
  faction_id   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  bounds_max_x INT UNSIGNED NOT NULL COMMENT 'límite del mapa: dato, no if en código',
  bounds_max_y INT UNSIGNED NOT NULL,
  zone_tier    ENUM('LOW','MID','HIGH') NOT NULL COMMENT 'eje del sesgo de drops y del gradiente de muerte',
  is_starter   TINYINT(1) NOT NULL DEFAULT 0,
  is_pvp       TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uk_map_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='mapas del mundo';

CREATE TABLE map_station (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  map_id       BIGINT UNSIGNED NOT NULL,
  station_type ENUM('HOME_BASE') NOT NULL COMMENT 'más tipos en E3+',
  faction_id   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  pos_x        INT UNSIGNED NOT NULL,
  pos_y        INT UNSIGNED NOT NULL,
  secure_range INT UNSIGNED NOT NULL DEFAULT 1500 COMMENT 'zona segura alrededor de la base',
  CONSTRAINT fk_station_map FOREIGN KEY (map_id) REFERENCES map(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='estaciones: el ancla de descargar/refinar/vender/reparar';

CREATE TABLE map_portal (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  map_id        BIGINT UNSIGNED NOT NULL,
  pos_x         INT UNSIGNED NOT NULL,
  pos_y         INT UNSIGNED NOT NULL,
  target_map_id BIGINT UNSIGNED NOT NULL COMMENT 'FK real: el destino existe por construcción y el protocolo lo transmite',
  target_pos_x  INT UNSIGNED NOT NULL,
  target_pos_y  INT UNSIGNED NOT NULL,
  is_visible    TINYINT(1) NOT NULL DEFAULT 1,
  is_working    TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_portal_map FOREIGN KEY (map_id) REFERENCES map(id),
  CONSTRAINT fk_portal_target FOREIGN KEY (target_map_id) REFERENCES map(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='portales entre mapas';

CREATE TABLE npc_catalog (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code              VARCHAR(32) NOT NULL,
  display_name      VARCHAR(64) NOT NULL COMMENT 'limpio: sin adornos ASCII; el tier es columna, no sufijo',
  species           VARCHAR(32) NOT NULL COMMENT 'vex, skarn, ferox, ...',
  threat_tier       ENUM('BASE','ELITE','TITAN','IMPERATOR') NOT NULL DEFAULT 'BASE',
  max_hp            INT UNSIGNED NOT NULL,
  max_shield        INT UNSIGNED NOT NULL DEFAULT 0,
  speed             SMALLINT UNSIGNED NOT NULL,
  damage            INT UNSIGNED NOT NULL,
  is_aggressive     TINYINT(1) NOT NULL DEFAULT 0,
  respawn_seconds   INT UNSIGNED NOT NULL DEFAULT 30,
  aggro_radius      INT UNSIGNED NOT NULL DEFAULT 500,
  reward_experience INT UNSIGNED NOT NULL DEFAULT 0,
  reward_honor      INT UNSIGNED NOT NULL DEFAULT 0,
  reward_credits    INT UNSIGNED NOT NULL DEFAULT 0,
  cargo_drop_min    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'unidades totales de material en su caja; la mezcla la fija zone_drop_bias',
  cargo_drop_max    INT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY uk_npc_catalog_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='catálogo de NPCs: tabla propia, jamás mezclada con naves de jugador';

CREATE TABLE map_npc_spawn (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  map_id         BIGINT UNSIGNED NOT NULL,
  npc_catalog_id BIGINT UNSIGNED NOT NULL,
  amount         SMALLINT UNSIGNED NOT NULL,
  UNIQUE KEY uk_spawn (map_id, npc_catalog_id),
  CONSTRAINT fk_spawn_map FOREIGN KEY (map_id) REFERENCES map(id),
  CONSTRAINT fk_spawn_npc FOREIGN KEY (npc_catalog_id) REFERENCES npc_catalog(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='población de NPCs por mapa (reemplaza el JSON sin FK del legado)';

CREATE TABLE zone_drop_bias (
  zone_tier      ENUM('LOW','MID','HIGH') NOT NULL,
  server_item_id BIGINT UNSIGNED NOT NULL,
  weight         DECIMAL(6,3) NOT NULL COMMENT 'peso relativo de la mezcla; la zona fija la mezcla, el NPC la cantidad',
  PRIMARY KEY (zone_tier, server_item_id),
  CONSTRAINT fk_bias_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='sesgo de drops por zona; invariante: ninguna zona replica la mezcla 50/33/17 de la receta';

-- estado en vivo de la nave: se crea después de map por la FK
CREATE TABLE player_ship_state (
  account_id     BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  map_id         BIGINT UNSIGNED NOT NULL,
  pos_x          INT UNSIGNED NOT NULL,
  pos_y          INT UNSIGNED NOT NULL,
  current_hp     INT UNSIGNED NOT NULL,
  current_shield INT UNSIGNED NOT NULL DEFAULT 0,
  is_destroyed   TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'hp=0 al login se resuelve con respawn gratis, jamás con bloqueo',
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ship_state_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_ship_state_map FOREIGN KEY (map_id) REFERENCES map(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='LA tabla caliente: un solo escritor (game server), write-behind; la lección del current_hit_points';

-- ============================================================
-- 6. MATERIALES Y ECONOMÍA DEL SLICE
-- ============================================================

CREATE TABLE player_cargo_hold (
  account_id     BIGINT UNSIGNED NOT NULL,
  server_item_id BIGINT UNSIGNED NOT NULL,
  amount         INT UNSIGNED NOT NULL,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (account_id, server_item_id),
  CONSTRAINT fk_cargo_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_cargo_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='la bodega volante: lo ÚNICO en riesgo; separada del almacén para que el gradiente de muerte sea posible';

CREATE TABLE player_resource_balance (
  account_id     BIGINT UNSIGNED NOT NULL,
  server_item_id BIGINT UNSIGNED NOT NULL COMMENT 'solo items con is_wallet_balance=1',
  amount         DECIMAL(20,6) NOT NULL DEFAULT 0,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (account_id, server_item_id),
  CONSTRAINT fk_balance_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_balance_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='almacén global + cartera; jamás en riesgo; escrituras SIEMPRE relativas (amount = amount + delta)';

CREATE TABLE refine_recipe (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  output_item_id BIGINT UNSIGNED NOT NULL,
  output_amount  INT UNSIGNED NOT NULL DEFAULT 1,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_recipe_output FOREIGN KEY (output_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='refinado automático al descargar en base: gratis, sin colas, sin timers';

CREATE TABLE refine_recipe_ingredient (
  recipe_id      BIGINT UNSIGNED NOT NULL,
  server_item_id BIGINT UNSIGNED NOT NULL,
  amount         INT UNSIGNED NOT NULL,
  PRIMARY KEY (recipe_id, server_item_id),
  CONSTRAINT fk_ingredient_recipe FOREIGN KEY (recipe_id) REFERENCES refine_recipe(id),
  CONSTRAINT fk_ingredient_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='ingredientes de la receta';

CREATE TABLE npc_sell_price (
  server_item_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  price_credits  DECIMAL(20,6) NOT NULL,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sell_price_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='precio de venta al NPC: dial de balanceo, no propiedad del catálogo';

CREATE TABLE economy_ledger (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id     BIGINT UNSIGNED NOT NULL,
  server_item_id BIGINT UNSIGNED NOT NULL,
  delta          DECIMAL(20,6) NOT NULL,
  reason         ENUM('NPC_KILL','CARGO_PICKUP','CARGO_UNLOAD','REFINE_IN','REFINE_OUT','NPC_SALE','REPAIR','ADMIN') NOT NULL,
  ref_id         BIGINT UNSIGNED NULL COMMENT 'id del evento origen si aplica',
  occurred_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_ledger_account (account_id, occurred_at),
  KEY ix_ledger_reason (reason, occurred_at),
  CONSTRAINT fk_ledger_account FOREIGN KEY (account_id) REFERENCES account(id),
  CONSTRAINT fk_ledger_item FOREIGN KEY (server_item_id) REFERENCES server_item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='append-only: grifos y sumideros; el invariante de convergencia se demuestra aquí, no con fe';

-- ============================================================
-- 7. CONFIGURACIÓN CALIBRABLE (escribe: api-admin, con auditoría)
-- ============================================================

CREATE TABLE server_setting (
  setting_key VARCHAR(64)  NOT NULL PRIMARY KEY,
  value       VARCHAR(256) NOT NULL,
  value_type  ENUM('INT','DECIMAL','BOOL','STRING') NOT NULL,
  min_value   DECIMAL(20,6) NULL,
  max_value   DECIMAL(20,6) NULL,
  unit        VARCHAR(16)  NULL,
  description VARCHAR(256) NOT NULL,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='escalares calibrables con tipo, rango y unidad; lo estructurado va en tablas propias';

CREATE TABLE server_setting_audit (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(64)  NOT NULL,
  old_value   VARCHAR(256) NULL,
  new_value   VARCHAR(256) NOT NULL,
  changed_by  VARCHAR(64)  NOT NULL COMMENT 'usuario de consola que movió el dial',
  changed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_setting_audit_key (setting_key, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='quién cambió qué número y cuándo';

-- ============================================================
-- 8. SEMILLAS DEL SLICE (valores provisionales hasta E6)
-- ============================================================

INSERT INTO server_item_category (code) VALUES
  ('currency'), ('material'), ('laser'), ('generator');

INSERT INTO server_item (item_key, loot_id, category_id, display_name, is_wallet_balance) VALUES
  ('credits',  'currency_credits',   (SELECT id FROM server_item_category WHERE code='currency'), 'Credits',  1),
  ('asterium', 'material_asterium',  (SELECT id FROM server_item_category WHERE code='material'), 'Asterium', 1),
  ('nebulium', 'material_nebulium',  (SELECT id FROM server_item_category WHERE code='material'), 'Nebulium', 1),
  ('coronium', 'material_coronium',  (SELECT id FROM server_item_category WHERE code='material'), 'Coronium', 1),
  ('aurorium', 'material_aurorium',  (SELECT id FROM server_item_category WHERE code='material'), 'Aurorium', 1),
  ('ion_1',    'laser_ion_1',        (SELECT id FROM server_item_category WHERE code='laser'),    'ION-1',    0),
  ('nan_1',    'generator_nan_1',    (SELECT id FROM server_item_category WHERE code='generator'),'NAN-1',    0);

INSERT INTO server_item_stat_type (code, unit) VALUES ('damage', 'hp'), ('shield', 'hp');

INSERT INTO server_item_stat (server_item_id, stat_type_id, value) VALUES
  ((SELECT id FROM server_item WHERE item_key='ion_1'), (SELECT id FROM server_item_stat_type WHERE code='damage'), 60),
  ((SELECT id FROM server_item WHERE item_key='nan_1'), (SELECT id FROM server_item_stat_type WHERE code='shield'), 1000);

INSERT INTO ship_catalog
  (code, display_name, tier, role, base_hp, base_shield, base_speed, laser_slots, generator_slots, heavy_gun_slots, extra_slots, cargo_capacity) VALUES
  ('phoenix', 'Phoenix', 'STARTER', NULL, 4000, 0, 320, 1, 1, 0, 1, 100);

INSERT INTO map (code, display_name, faction_id, bounds_max_x, bounds_max_y, zone_tier, is_starter, is_pvp) VALUES
  ('1-1', 'Umbra 1-1', 1, 20800, 12800, 'LOW', 1, 0);

INSERT INTO map_station (map_id, station_type, faction_id, pos_x, pos_y, secure_range) VALUES
  ((SELECT id FROM map WHERE code='1-1'), 'HOME_BASE', 1, 2000, 2000, 1500);

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('vex', 'Vex', 'vex', 'BASE', 8000, 4000, 270, 120, 0, 30, 500, 400, 2, 400, 30, 60);

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='vex'), 15);

INSERT INTO zone_drop_bias (zone_tier, server_item_id, weight) VALUES
  ('LOW',  (SELECT id FROM server_item WHERE item_key='asterium'), 60),
  ('LOW',  (SELECT id FROM server_item WHERE item_key='nebulium'), 30),
  ('LOW',  (SELECT id FROM server_item WHERE item_key='coronium'), 10),
  ('MID',  (SELECT id FROM server_item WHERE item_key='asterium'), 30),
  ('MID',  (SELECT id FROM server_item WHERE item_key='nebulium'), 45),
  ('MID',  (SELECT id FROM server_item WHERE item_key='coronium'), 25),
  ('HIGH', (SELECT id FROM server_item WHERE item_key='asterium'), 15),
  ('HIGH', (SELECT id FROM server_item WHERE item_key='nebulium'), 30),
  ('HIGH', (SELECT id FROM server_item WHERE item_key='coronium'), 55);

INSERT INTO refine_recipe (output_item_id, output_amount) VALUES
  ((SELECT id FROM server_item WHERE item_key='aurorium'), 1);

INSERT INTO refine_recipe_ingredient (recipe_id, server_item_id, amount)
SELECT r.id, i.id, x.amount
FROM refine_recipe r
JOIN server_item o ON o.id = r.output_item_id AND o.item_key = 'aurorium'
JOIN (SELECT 'asterium' AS item_key, 30 AS amount
      UNION ALL SELECT 'nebulium', 20
      UNION ALL SELECT 'coronium', 10) x
JOIN server_item i ON i.item_key = x.item_key;

INSERT INTO npc_sell_price (server_item_id, price_credits) VALUES
  ((SELECT id FROM server_item WHERE item_key='asterium'), 10),
  ((SELECT id FROM server_item WHERE item_key='nebulium'), 15),
  ((SELECT id FROM server_item WHERE item_key='coronium'), 25);

INSERT INTO server_setting (setting_key, value, value_type, min_value, max_value, unit, description) VALUES
  ('portal_jump_delay_ms',     '3250', 'INT', 0, 10000, 'ms',  'retardo del salto de portal'),
  ('reconnect_grace_seconds',  '60',   'INT', 0, 600,   's',   'ventana de gracia para el resume de sesión'),
  ('ship_state_flush_seconds', '30',   'INT', 5, 300,   's',   'cadencia máxima del write-behind de player_ship_state'),
  ('registration_open',        '0',    'BOOL', NULL, NULL, NULL, 'si la api acepta registros públicos (beta cerrada = 0)');

-- ---------- registrar la migración ----------
INSERT INTO schema_migration (version) VALUES ('2026.08.25.1');
