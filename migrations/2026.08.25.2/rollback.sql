-- Rollback de 2026.08.25.2 — restaura los stats de seed del Vex.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog
SET max_hp = 8000, max_shield = 4000
WHERE code = 'vex';

DELETE FROM schema_migration WHERE version = '2026.08.25.2';
