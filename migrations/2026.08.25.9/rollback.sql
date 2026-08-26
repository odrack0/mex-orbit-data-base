-- Rollback de 2026.08.25.9 — el 1-1 vuelve a cinco especies.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

DELETE s FROM map_npc_spawn s
JOIN npc_catalog n ON n.id = s.npc_catalog_id
WHERE n.code IN ('gravit', 'mordax');

DELETE FROM npc_catalog WHERE code IN ('gravit', 'mordax');

DELETE FROM schema_migration WHERE version = '2026.08.25.9';
