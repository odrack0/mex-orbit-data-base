-- ============================================================
-- Migración 2026.09.02.3 — ACI-02 (nombre temporal): undécima especie del 1-1
--
-- Segunda máquina de la serie ACI: un platillo con tentáculos y un ojo
-- principal. Más lento y más duro que el ACI-01; entra en la escalera del
-- 1-1 entre el Gravit y el Vexor.
--
-- Escalera por vida efectiva (casco + escudo) y TTK con el ION-1 (120 dps):
--   Drony/ACI-01  1.500 → 12,5 s
--   Gravit        1.800 → 15 s
--   ACI-02        2.000 → 16,7 s   ← nuevo
--   Vexor         2.400 → 20 s
-- Créditos por punto de vida efectiva 0,33, como sus vecinos. Velocidad 260
-- (por debajo del Vexor, 300). Daño 10 como todas las especies. Carroñero
-- (is_aggressive 0).
--
-- Stats PROVISIONALES por escalera. Requiere reiniciar el game server y el
-- cliente con data/npcs/aci-02.json + assets/npcs/aci-02.glb.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('aci-02', 'ACI-02', 'aci-02', 'BASE', 1200, 800, 260, 10, 0, 40, 500, 700, 3, 650, 50, 90);

INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='aci-02'), 5);

INSERT INTO schema_migration (version) VALUES ('2026.09.02.3');
