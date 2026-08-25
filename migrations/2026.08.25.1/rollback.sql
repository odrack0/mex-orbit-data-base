-- ============================================================
-- Rollback de 2026.08.25.1 — revierte el esquema inicial completo.
-- Orden inverso de dependencias; deja la base de datos vacía.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- configuración
DROP TABLE IF EXISTS server_setting_audit;
DROP TABLE IF EXISTS server_setting;

-- economía del slice
DROP TABLE IF EXISTS economy_ledger;
DROP TABLE IF EXISTS npc_sell_price;
DROP TABLE IF EXISTS refine_recipe_ingredient;
DROP TABLE IF EXISTS refine_recipe;
DROP TABLE IF EXISTS player_resource_balance;
DROP TABLE IF EXISTS player_cargo_hold;

-- estado en vivo y mundo
DROP TABLE IF EXISTS player_ship_state;
DROP TABLE IF EXISTS zone_drop_bias;
DROP TABLE IF EXISTS map_npc_spawn;
DROP TABLE IF EXISTS npc_catalog;
DROP TABLE IF EXISTS map_portal;
DROP TABLE IF EXISTS map_station;
DROP TABLE IF EXISTS map;

-- naves
DROP TABLE IF EXISTS player_ship;
DROP TABLE IF EXISTS ship_catalog;

-- items del jugador y equipo
DROP TABLE IF EXISTS player_equipment_slot;
DROP TABLE IF EXISTS player_item_stat;
DROP TABLE IF EXISTS player_item;

-- catálogo
DROP TABLE IF EXISTS server_item_stat;
DROP TABLE IF EXISTS server_item_stat_type;
DROP TABLE IF EXISTS server_item;
DROP TABLE IF EXISTS server_item_category;

-- cuentas y sesiones
DROP TABLE IF EXISTS login_audit;
DROP TABLE IF EXISTS game_session;
DROP TABLE IF EXISTS api_session;
DROP TABLE IF EXISTS account;

-- registro del runner (esta migración lo creó; revertirla lo retira)
DROP TABLE IF EXISTS schema_migration;
