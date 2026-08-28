-- Vuelve a apagar el combate NPC->jugador y devuelve a cada especie su daño
-- calibrado en la migracion .7. Especie por especie: un UPDATE plano de vuelta
-- perderia la escalera, que es justo lo que costo medir.
START TRANSACTION;

UPDATE server_setting SET value = '0' WHERE setting_key = 'npc_combat_enabled';

UPDATE npc_catalog SET damage = 25 WHERE code = 'vex';
UPDATE npc_catalog SET damage = 35 WHERE code = 'gravit';
UPDATE npc_catalog SET damage = 40 WHERE code = 'vexor';
UPDATE npc_catalog SET damage = 55 WHERE code = 'skarn';
UPDATE npc_catalog SET damage = 60 WHERE code = 'gravon';
UPDATE npc_catalog SET damage = 65 WHERE code = 'mordax';
UPDATE npc_catalog SET damage = 70 WHERE code = 'ferox';
UPDATE npc_catalog SET damage = 75 WHERE code = 'skarnox';
UPDATE npc_catalog SET damage = 85 WHERE code = 'vorax';

DELETE FROM schema_migration WHERE version = '2026.08.28.2';
COMMIT;
