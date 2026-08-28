-- 2026.08.28.2 — se enciende el combate NPC->jugador, con el daño aplanado a 10.
--
-- El interruptor `npc_combat_enabled` llevaba en 0 desde la migracion .11: los
-- bichos vagabundeaban, fichaban y perseguian, pero no hacian daño. Se enciende
-- ahora que el bicho golpeado si persigue de verdad (hasta hoy el frenazo al
-- recibir un golpe cancelaba su propia persecucion, asi que encenderlo antes
-- habria sido encender un combate a medias).
--
-- Y el daño de TODAS las especies baja a 10, a proposito y de forma temporal.
-- Los valores actuales (25-85) se calibraron en la migracion .7 contra un
-- jugador que no podia ser perseguido; con la persecucion arreglada y el
-- combate encendido, la dificultad real esta sin medir. 10 para todos es un
-- suelo plano desde el que calibrar mirando, en vez de heredar numeros de un
-- mundo que ya no existe.
--
-- El rollback devuelve especie por especie sus valores exactos.
--
-- Requiere: mex-orbit-game-server con la persecucion arreglada y el DMZ que
-- permite devolver el golpe.

START TRANSACTION;

UPDATE server_setting SET value = '1' WHERE setting_key = 'npc_combat_enabled';

UPDATE npc_catalog SET damage = 10;

INSERT INTO schema_migration (version) VALUES ('2026.08.28.2');

COMMIT;
