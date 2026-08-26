-- Rollback de 2026.08.25.10 — el 1-1 vuelve a siete especies y el catalogo
-- pierde la columna de huida.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

DELETE s FROM map_npc_spawn s
JOIN npc_catalog n ON n.id = s.npc_catalog_id
WHERE n.code IN ('gravon', 'vorax');

DELETE FROM npc_catalog WHERE code IN ('gravon', 'vorax');

ALTER TABLE npc_catalog DROP COLUMN flee_hp_pct;

DELETE FROM schema_migration WHERE version = '2026.08.25.10';
