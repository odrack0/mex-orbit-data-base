-- Quita los diales de relevancia. Sin las filas, el game server usa sus valores
-- de respaldo (2000 / 1250 / 10%): un dial ausente jamas debe tumbar el arranque.
START TRANSACTION;

DELETE FROM server_setting
 WHERE setting_key IN ('render_range_entities', 'render_range_objects',
                       'render_range_hysteresis_pct');

DELETE FROM schema_migration WHERE version = '2026.08.28.1';
COMMIT;
