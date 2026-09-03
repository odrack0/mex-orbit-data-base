-- Rollback de 2026.09.02.2 — aci-01 vuelve a llamarse drony.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET code = 'drony', display_name = 'Drony', species = 'drony' WHERE code = 'aci-01';

DELETE FROM schema_migration WHERE version = '2026.09.02.2';
