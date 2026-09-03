-- ============================================================
-- Migración 2026.09.02.6 — ACI-05 (nombre temporal): decimocuarta especie del 1-1
--
-- Quinta máquina de la serie ACI: un ojo en la cara superior que es su proa.
-- La más dura de la serie hasta hoy; entra en la escalera del 1-1 entre el
-- Skarn y el Ferox.
--
-- Escalera por vida efectiva (casco + escudo) y TTK con el ION-1 (120 dps):
--   Skarn   3.200 → 27 s
--   ACI-05  3.600 → 30 s   ← nuevo
--   Ferox   4.000 → 33 s
-- Créditos por punto de vida efectiva 0,36. Velocidad 280. Daño 10.
-- Carroñero (is_aggressive 0).
--
-- Stats PROVISIONALES por escalera. Requiere reiniciar el game server y el
-- cliente con data/npcs/aci-05.json + assets/npcs/aci-05.glb.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('aci-05', 'ACI-05', 'aci-05', 'BASE', 2100, 1500, 280, 10, 0, 65, 550, 1600, 7, 1300, 90, 150);

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='aci-05'), 3);

INSERT INTO schema_migration (version) VALUES ('2026.09.02.6');
