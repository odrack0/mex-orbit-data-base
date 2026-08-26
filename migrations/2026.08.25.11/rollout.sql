-- ============================================================
-- Migración 2026.08.25.11 — interruptor del combate NPC→jugador
--
-- `npc_combat_enabled` apaga el disparo de los NPCs sin tocar el resto de su
-- IA: siguen vagabundeando por el mapa, siguen fichándote y persiguiéndote, y
-- el Vorax sigue huyendo malherido. Lo único que no ocurre es el daño.
--
-- Se apaga (0) por petición de diseño mientras se juega el sector con calma.
-- Volver a encenderlo es un UPDATE y reiniciar el game server — que además
-- queda asentado en `server_setting_audit`, así que se sabe quién lo movió.
--
-- Va aquí y no en appsettings.json porque es una decisión de JUEGO, no de
-- despliegue: la regla del proyecto es que esos números viven en BD.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO server_setting (setting_key, value, value_type, min_value, max_value, unit, description) VALUES
  ('npc_combat_enabled', '0', 'BOOL', 0, 1, NULL,
   'si los NPC disparan al jugador; 0 = vuelan y persiguen pero no hacen daño');

INSERT INTO schema_migration (version) VALUES ('2026.08.25.11');
