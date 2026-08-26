-- Vuelve al estado de la .3: un solo mapa vecino y su portal de ida.
START TRANSACTION;

DELETE FROM map_portal;

INSERT INTO map_portal (map_id, pos_x, pos_y, target_map_id, target_pos_x, target_pos_y, is_visible, is_working)
SELECT o.id, 18800, 6400, d.id, 2000, 6400, 1, 1
FROM map o JOIN map d ON d.code = '1-2' WHERE o.code = '1-1';

DELETE FROM map WHERE code NOT IN ('1-1', '1-2');

DELETE FROM schema_migration WHERE version = '2026.08.26.1';
COMMIT;
