-- ============================================================
-- Migración 2026.09.02.1 — Drony: décima especie del 1-1
--
-- Taxonomía: Drony = especie NUEVA, mecánica (un dron pequeño y ágil, no un
-- bicho biológico ni mineral). Su identidad es ser numeroso y rápido de
-- matar: entra en la escalera del 1-1 entre el Vex y el Gravit.
--
-- Escalera del 1-1 por vida efectiva (casco + escudo) y TTK con el ION-1
-- (120 dps):
--   Vex     1.200 → 10 s
--   Drony   1.500 → 12,5 s   ← nuevo
--   Gravit  1.800 → 15 s
--   Vexor   2.400 → 20 s
-- Créditos por punto de vida efectiva: 0,33 (Vex) · 0,33 (Drony) · 0,33
-- (Gravit): misma banda que sus vecinos. Velocidad 320: ágil, por encima del
-- Vexor (300) y por debajo del Ferox (420). Daño 10, como todas las especies
-- desde 2026.08.28.2. is_aggressive 0: carroñero, no cazador.
--
-- Stats PROVISIONALES: calibrados por la escalera, no probados en vivo.
-- Requiere: reiniciar el game server (carga el catálogo al arrancar) y el
-- cliente con data/npcs/drony.json + assets/npcs/drony.glb.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('drony', 'Drony', 'drony', 'BASE', 900, 600, 320, 10, 0, 35, 500, 500, 2, 500, 35, 70);

-- reparto del 1-1: numeroso, entre el Vex (15) y el Gravit (9)
INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='drony'), 6);

INSERT INTO schema_migration (version) VALUES ('2026.09.02.1');
