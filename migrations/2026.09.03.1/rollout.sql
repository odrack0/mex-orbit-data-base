-- ============================================================
-- Migración 2026.09.03.1 — El 1-1 se queda solo con la serie ACI (temporal)
--
-- Mientras se afina la serie ACI (aci-01 a aci-05), las nueve especies
-- anteriores (Vex, Vexor, Skarn, Ferox, Skarnox, Gravit, Mordax, Gravon,
-- Vorax) salen del reparto del 1-1. Siguen en npc_catalog: el rollback
-- devuelve los spawns con las cantidades que tenían (15/8/5/4/2/9/5/3/3).
-- Requiere reiniciar el game server (carga el reparto al arrancar) y
-- cambiar la presa del autotest del cliente (cazaba Vex/Vexor).
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

DELETE s FROM map_npc_spawn s
JOIN npc_catalog n ON n.id = s.npc_catalog_id
JOIN map m ON m.id = s.map_id
WHERE m.code = '1-1'
  AND n.code IN ('vex', 'vexor', 'skarn', 'ferox', 'skarnox', 'gravit', 'mordax', 'gravon', 'vorax');

INSERT INTO schema_migration (version) VALUES ('2026.09.03.1');
