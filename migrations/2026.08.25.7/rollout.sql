-- ============================================================
-- Migración 2026.08.25.7 — primera calibración del daño de los NPCs
--
-- Hasta ahora `npc_catalog.damage` era un número que NADIE leía: el server
-- cargaba el dial pero no existía combate NPC→jugador. Al encender la IA quedó
-- claro que esos valores no estaban calibrados contra nada — el autotest murió
-- en ~15 s contra un solo Ferox (340 de daño por segundo contra los 5.000 de
-- vida efectiva de una Phoenix: 4.000 de casco + 1.000 del NAN-1).
--
-- Criterio nuevo: el daño se fija por **cuánto te cuesta matarlo**. Cada bicho
-- te muerde una fracción de tu vida durante SU propio TTK, y esa fracción crece
-- con la escalera del mapa:
--
--   Bicho    TTK    daño/s   te cuesta   % de una Phoenix llena
--   Vex      10 s     25       250          5%
--   Vexor    20 s     40       800         16%
--   Skarn    27 s     55     1.485         30%
--   Ferox    33 s     70     2.310         46%
--   Skarnox  47 s     75     3.525         71%
--
-- El Skarnox se lleva casi tres cuartos de tu barra: es el techo del 1-1 y debe
-- obligarte a volver a la base, no matarte de un mordisco.
--
-- Ojo: solo el Ferox es agresivo. Los otros cuatro únicamente devuelven el
-- fuego, así que estos números aplican mientras TÚ los estás matando.
--
-- Provisionales, como el resto de los stats, hasta el balanceo de E6.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET damage = 25 WHERE code = 'vex';
UPDATE npc_catalog SET damage = 40 WHERE code = 'vexor';
UPDATE npc_catalog SET damage = 55 WHERE code = 'skarn';
UPDATE npc_catalog SET damage = 70 WHERE code = 'ferox';
UPDATE npc_catalog SET damage = 75 WHERE code = 'skarnox';

INSERT INTO schema_migration (version) VALUES ('2026.08.25.7');
