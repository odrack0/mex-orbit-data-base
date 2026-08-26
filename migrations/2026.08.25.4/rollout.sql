-- ============================================================
-- Migración 2026.08.25.4 — Vexor y Skarn: el bestiario del 1-1 crece a tres
--
-- Taxonomía (guidelines §nomenclatura de aliens):
--   · Vexor = MISMA especie que el Vex, sufijo -or = forma mayor. Sigue siendo
--     tier BASE: Elite/Titan son la escalera de jefes, no un escalón de zona.
--   · Skarn = ESPECIE NUEVA (roca dura, término geológico real). Enseña que el
--     bestiario tiene familias, no una criatura en varios tamaños.
--
-- TTK con el ION-1 del arranque (60 de daño cada 500 ms = 120 dps), sobre
-- casco + escudo, que es lo que hay que atravesar:
--   Vex   1.200 →  10 s     (referencia ya calibrada en la migración .2)
--   Vexor 2.400 →  20 s
--   Skarn 3.200 →  27 s
-- Créditos por punto de vida efectiva: 0,33 → 0,35 → 0,41. La recompensa sube
-- un poco más rápido que la dificultad: pelear arriba tiene que compensar.
-- Provisionales hasta la pasada de balanceo (E6), como los del Vex.
--
-- is_aggressive queda en 0 en los tres: el server carga el dial pero todavía no
-- existe combate NPC→jugador. Cuando llegue, se enciende aquí, no en código.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('vexor', 'Vexor', 'vex',   'BASE', 1600,  800, 300, 200, 0, 45, 600,  900, 4,  850,  55, 100),
  ('skarn', 'Skarn', 'skarn', 'BASE', 2000, 1200, 210, 260, 0, 60, 550, 1500, 6, 1300,  80, 140);

-- reparto del 1-1: la plaga manda, el Vexor es ocasional y el Skarn escaso
INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='vexor'), 8),
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='skarn'), 5);

INSERT INTO schema_migration (version) VALUES ('2026.08.25.4');
