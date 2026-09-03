-- ============================================================
-- Migración 2026.09.02.4 — ACI-03 (nombre temporal): duodécima especie del 1-1
--
-- Tercera máquina de la serie ACI: una media luna rápida con la cápsula del
-- ojo en el vértice. Más rápida y algo más dura que el Vexor; entra en la
-- escalera del 1-1 entre el Vexor y el Skarn.
--
-- Escalera por vida efectiva (casco + escudo) y TTK con el ION-1 (120 dps):
--   Vexor   2.400 → 20 s
--   ACI-03  2.600 → 21,7 s   ← nuevo
--   Skarn   3.200 → 27 s
-- Créditos por punto de vida efectiva 0,35. Velocidad 340 (por encima del
-- Vexor, 300; por debajo del Ferox, 420). Daño 10. Carroñero (is_aggressive 0).
--
-- Stats PROVISIONALES por escalera. Requiere reiniciar el game server y el
-- cliente con data/npcs/aci-03.json + assets/npcs/aci-03.glb.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('aci-03', 'ACI-03', 'aci-03', 'BASE', 1500, 1100, 340, 10, 0, 50, 550, 1100, 5, 900, 65, 120);

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='aci-03'), 4);

INSERT INTO schema_migration (version) VALUES ('2026.09.02.4');
