-- ============================================================
-- Migración 2026.09.02.5 — ACI-04 (nombre temporal): decimotercera especie del 1-1
--
-- Cuarta máquina de la serie ACI: una esfera blindada con un ojo y un par
-- de tenazas. La más dura de la serie; entra en la escalera del 1-1 entre
-- el ACI-03 y el Skarn.
--
-- Escalera por vida efectiva (casco + escudo) y TTK con el ION-1 (120 dps):
--   ACI-03  2.600 → 21,7 s
--   ACI-04  3.100 → 25,8 s   ← nuevo
--   Skarn   3.200 → 27 s
-- Créditos por punto de vida efectiva 0,35. Velocidad 250 (pesada). Daño 10.
-- Carroñero (is_aggressive 0).
--
-- Stats PROVISIONALES por escalera. Requiere reiniciar el game server y el
-- cliente con data/npcs/aci-04.json + assets/npcs/aci-04.glb.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('aci-04', 'ACI-04', 'aci-04', 'BASE', 1800, 1300, 250, 10, 0, 55, 550, 1300, 6, 1100, 75, 130);

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='aci-04'), 4);

INSERT INTO schema_migration (version) VALUES ('2026.09.02.5');
