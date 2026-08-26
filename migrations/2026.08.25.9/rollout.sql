-- ============================================================
-- Migración 2026.08.25.9 — Gravit y Mordax: el bestiario del 1-1 llega a siete
--
-- Taxonomía (guidelines §nomenclatura de aliens):
--   · Gravit = primer bicho con sufijo **-it**, que significa FORMA MENOR. Hasta
--     ahora el jugador solo había visto los sufijos mayores (Vex→Vexor,
--     Skarn→Skarnox); con este aprende la otra mitad de la regla. Su forma mayor
--     —el Gravon— existe en la taxonomía y llegará después: el nombre ya
--     promete que hay algo más grande ahí fuera.
--   · Mordax = "el que muerde". Su nombre es una promesa MECÁNICA, no un
--     adorno: es agresivo pero de radio corto (350 frente a los 700 del Ferox).
--     No te caza por medio sector; muerde lo que se le acerca.
--
-- DECISIÓN DE ESCALERA: estos dos NO suben el techo del mapa. El Skarnox ya
-- pide 47 s con el ION-1, y estirar más el 1-1 lo vuelve un peaje. Ambos caen
-- DENTRO de la banda existente, para dar variedad sin alargar la partida:
--
--   Vex     1.200 → 10 s
--   Gravit  1.800 → 15 s   ← nuevo
--   Vexor   2.400 → 20 s
--   Skarn   3.200 → 27 s
--   Mordax  3.600 → 30 s   ← nuevo
--   Ferox   4.000 → 33 s
--   Skarnox 5.600 → 47 s   ← sigue siendo el techo
--
-- Daño por el criterio de la migración .7 (cuánto te cuesta matarlo, sobre los
-- 5.000 de vida efectiva de una Phoenix): Gravit 35/s = 10% de tu barra;
-- Mordax 65/s = 39%. Los créditos por punto de vida efectiva siguen la curva
-- ascendente ya establecida (0,33 en el Vex → 0,46 en el Skarnox).
--
-- El Mordax es el SEGUNDO agresivo del mapa, tras el Ferox. Son roles
-- distintos: el Ferox caza de lejos, el Mordax solo si te metes en su radio.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('gravit', 'Gravit', 'gravis', 'BASE', 1000,  800, 170, 35, 0, 35, 400,  650, 3,  600, 45,  80),
  ('mordax', 'Mordax', 'mordax', 'BASE', 2200, 1400, 340, 65, 1, 55, 350, 1800, 7, 1500, 95, 160);

-- reparto del 1-1: el menor es abundante, el mordedor escaso
INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='gravit'), 9),
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='mordax'), 5);

INSERT INTO schema_migration (version) VALUES ('2026.08.25.9');
