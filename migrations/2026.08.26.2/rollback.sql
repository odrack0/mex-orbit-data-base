-- Vuelve a la llegada separada del portal y quita el directorio.
START TRANSACTION;

DROP TABLE IF EXISTS map_server;

-- 1800 unidades hacia el centro del mapa, como sembro la .1
UPDATE map_portal p
  JOIN map_portal v ON v.map_id = p.target_map_id AND v.target_map_id = p.map_id
  JOIN map m ON m.id = p.target_map_id
SET p.target_pos_x = ROUND(v.pos_x + (m.bounds_max_x/2 - v.pos_x)
      / GREATEST(SQRT(POW(m.bounds_max_x/2 - v.pos_x,2) + POW(m.bounds_max_y/2 - v.pos_y,2)),1) * 1800),
    p.target_pos_y = ROUND(v.pos_y + (m.bounds_max_y/2 - v.pos_y)
      / GREATEST(SQRT(POW(m.bounds_max_x/2 - v.pos_x,2) + POW(m.bounds_max_y/2 - v.pos_y,2)),1) * 1800);

DELETE FROM schema_migration WHERE version = '2026.08.26.2';
COMMIT;
