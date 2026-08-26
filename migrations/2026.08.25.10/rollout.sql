-- ============================================================
-- Migración 2026.08.25.10 — Gravon y Vorax: el bestiario del 1-1 llega a nueve
--
-- Taxonomía (guidelines §nomenclatura de aliens):
--   · Gravon cierra la pareja que el Gravit dejó abierta. Sufijo -on = forma
--     mayor, igual que -or y -ox. Es la TERCERA pareja del mapa (Vex→Vexor,
--     Skarn→Skarnox, Gravit→Gravon): a la tercera, la regla de sufijos ya no
--     necesita que nadie la explique.
--   · Vorax es el primer bicho cuyo nombre describe una CONDUCTA y no una
--     forma: huye cuando lo tienes casi muerto. Para eso entra la columna
--     `flee_hp_pct` de abajo.
--
-- COLUMNA NUEVA: `npc_catalog.flee_hp_pct`. 0 = no huye jamás (los ocho
-- anteriores). El Vorax huye por debajo del 30% de casco. Es un dial de BD, no
-- un `if` por especie en el código: cualquier bicho futuro puede ser cobarde
-- sin tocar el server.
--
-- Escalera: ninguno de los dos sube el techo. El Skarnox sigue mandando con sus
-- 47 s; estirar más el 1-1 lo volvería un peaje (misma decisión que en la .9).
--
--   Vex     1.200 → 10 s      Mordax  3.600 → 30 s
--   Gravit  1.800 → 15 s      Ferox   4.000 → 33 s
--   Vexor   2.400 → 20 s      Gravon  4.500 → 37 s   ← nuevo
--   Skarn   3.200 → 27 s      Vorax   4.800 → 40 s   ← nuevo
--                             Skarnox 5.600 → 47 s   ← sigue siendo el techo
--
-- Daño por el criterio de la .7 (cuánto te cuesta matarlo, sobre los 5.000 de
-- vida efectiva de una Phoenix), pero con personalidad: el Gravon es un tanque
-- lento que pega flojo para lo que aguanta (60/s = 45% de tu barra), y el Vorax
-- pega duro (85/s = 68%). Sus créditos son los más altos del mapa a propósito:
-- si consigues rematarlo antes de que escape, tiene que compensar.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

ALTER TABLE npc_catalog
  ADD COLUMN flee_hp_pct TINYINT UNSIGNED NOT NULL DEFAULT 0
  COMMENT 'huye por debajo de este % de casco; 0 = jamás huye'
  AFTER is_aggressive;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   flee_hp_pct, respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits,
   cargo_drop_min, cargo_drop_max) VALUES
  ('gravon', 'Gravon', 'gravis', 'BASE', 2800, 1700, 160, 60, 0,  0, 80, 450, 2600,  9, 2000, 130, 210),
  ('vorax',  'Vorax',  'vorax',  'BASE', 3000, 1800, 380, 85, 1, 30, 100, 650, 3000, 12, 2400, 140, 230);

-- reparto del 1-1: los dos son escasos, y el Vorax mas todavia
INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='gravon'), 3),
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='vorax'), 3);

INSERT INTO schema_migration (version) VALUES ('2026.08.25.10');
