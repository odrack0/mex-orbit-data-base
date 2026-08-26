-- Rollback de 2026.08.25.7 — devuelve el daño sin calibrar de las migraciones
-- .1, .4 y .5 (los valores que mataban al jugador en 15 s).

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET damage = 120 WHERE code = 'vex';
UPDATE npc_catalog SET damage = 200 WHERE code = 'vexor';
UPDATE npc_catalog SET damage = 260 WHERE code = 'skarn';
UPDATE npc_catalog SET damage = 340 WHERE code = 'ferox';
UPDATE npc_catalog SET damage = 400 WHERE code = 'skarnox';

DELETE FROM schema_migration WHERE version = '2026.08.25.7';
