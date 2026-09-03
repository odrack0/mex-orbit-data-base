-- Rollback de 2026.09.03.1 — vuelven las nueve especies al 1-1 con sus cantidades.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount)
SELECT m.id, n.id, x.amount
FROM (SELECT 'vex' code, 15 amount UNION ALL SELECT 'vexor', 8 UNION ALL SELECT 'skarn', 5
      UNION ALL SELECT 'ferox', 4 UNION ALL SELECT 'skarnox', 2 UNION ALL SELECT 'gravit', 9
      UNION ALL SELECT 'mordax', 5 UNION ALL SELECT 'gravon', 3 UNION ALL SELECT 'vorax', 3) x
JOIN npc_catalog n ON n.code = x.code
JOIN map m ON m.code = '1-1';

DELETE FROM schema_migration WHERE version = '2026.09.03.1';
