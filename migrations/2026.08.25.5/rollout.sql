-- ============================================================
-- Migración 2026.08.25.5 — Ferox y Skarnox: el bestiario del 1-1 llega a cinco
--
-- Taxonomía (guidelines §nomenclatura de aliens):
--   · Skarnox = forma mayor del Skarn (sufijo -ox). Es la SEGUNDA pareja
--     base→mayor del mapa: con Vex→Vexor el jugador vio la regla una vez, con
--     Skarn→Skarnox la aprende. La morfología del nombre enseña sola.
--   · Ferox = TERCERA especie (latín ferox, feroz). Su identidad no es aguantar
--     sino alcanzarte: es el bicho rápido del 1-1 (speed 420, el mayor del mapa,
--     por encima incluso de la Phoenix con 320).
--
-- Escalera del 1-1 por vida efectiva (casco + escudo) y TTK con el ION-1 del
-- arranque (60 de daño cada 500 ms = 120 dps):
--   Vex     1.200 → 10 s
--   Vexor   2.400 → 20 s
--   Skarn   3.200 → 27 s
--   Ferox   4.000 → 33 s
--   Skarnox 5.600 → 47 s   ← el techo del mapa
-- Créditos por punto de vida efectiva: 0,33 · 0,35 · 0,41 · 0,44 · 0,46. La
-- recompensa sigue subiendo más rápido que la dificultad.
--
-- ⚠️ DEUDA CONOCIDA: 47 s de TTK es largo, y no es culpa del Skarnox — es que
-- el ION-1 es el ÚNICO láser del catálogo. La cima del mapa inicial pide una
-- segunda grada de láser, no bichos más flojos. Se revisa en el balanceo (E6).
--
-- Sus cajas (110-180 y 150-240) DESBORDAN la bodega de 100 de la Phoenix a
-- propósito: la recogida parcial ya está implementada, y así el jugador siente
-- la necesidad de más bodega en vez de que se la expliquen.
--
-- is_aggressive sigue en 0 en los cinco: el server carga el dial pero todavía no
-- existe combate NPC→jugador. Con el Ferox esto duele más que antes — un cazador
-- que no caza — y es el primer candidato a encenderlo cuando llegue.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO npc_catalog
  (code, display_name, species, threat_tier, max_hp, max_shield, speed, damage, is_aggressive,
   respawn_seconds, aggro_radius, reward_experience, reward_honor, reward_credits, cargo_drop_min, cargo_drop_max) VALUES
  ('ferox',   'Ferox',   'ferox', 'BASE', 2400, 1600, 420, 340, 0, 75, 700, 2100,  8, 1750, 110, 180),
  ('skarnox', 'Skarnox', 'skarn', 'BASE', 3600, 2000, 190, 400, 0, 90, 500, 3000, 11, 2600, 150, 240);

-- reparto del 1-1: cuanto más arriba en la escalera, más escaso
INSERT INTO map_npc_spawn (map_id, npc_catalog_id, amount) VALUES
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='ferox'), 4),
  ((SELECT id FROM map WHERE code='1-1'), (SELECT id FROM npc_catalog WHERE code='skarnox'), 2);

INSERT INTO schema_migration (version) VALUES ('2026.08.25.5');
