-- 2026.08.26.1 — el sistema estelar: 29 mapas y 42 puertas (84 portales).
--
-- El grafo NO se escribio a mano: se extrajo del arte original del mapa estelar
-- (mex-orbit-docs/04-pilares/08-sistema-estelar.md) por analisis de imagen, y se
-- valido por dos caminos que no se impusieron — el recuento de etiquetas J1..J42
-- del original, y la simetria de las tres facciones.
--
-- El legado NO se uso salvo para las tres puertas CENTRALES a 4-4, que son las
-- unicas que el arte no puede dibujar: el mapa estelar solo pinta cruces de borde
-- a borde y esas estan en mitad del mapa.

START TRANSACTION;

-- Los mapas. 1-1 y 1-2 ya existian: INSERT IGNORE los respeta con su nombre y su
-- is_starter intactos.
INSERT IGNORE INTO map (code, display_name, faction_id, bounds_max_x, bounds_max_y, zone_tier, is_starter, is_pvp) VALUES
  ('1-1', 'Umbra 1-1', 1, 20800, 12800, 'LOW', 0, 0),
  ('1-2', 'Umbra 1-2', 1, 20800, 12800, 'LOW', 0, 0),
  ('1-3', 'Umbra 1-3', 1, 20800, 12800, 'LOW', 0, 0),
  ('1-4', 'Umbra 1-4', 1, 20800, 12800, 'LOW', 0, 0),
  ('1-5', 'Umbra 1-5', 1, 20800, 12800, 'MID', 0, 0),
  ('1-6', 'Umbra 1-6', 1, 20800, 12800, 'MID', 0, 0),
  ('1-7', 'Umbra 1-7', 1, 20800, 12800, 'MID', 0, 0),
  ('1-8', 'Umbra 1-8', 1, 20800, 12800, 'MID', 0, 0),
  ('2-1', 'Sector 2-1', 2, 20800, 12800, 'LOW', 0, 0),
  ('2-2', 'Sector 2-2', 2, 20800, 12800, 'LOW', 0, 0),
  ('2-3', 'Sector 2-3', 2, 20800, 12800, 'LOW', 0, 0),
  ('2-4', 'Sector 2-4', 2, 20800, 12800, 'LOW', 0, 0),
  ('2-5', 'Sector 2-5', 2, 20800, 12800, 'MID', 0, 0),
  ('2-6', 'Sector 2-6', 2, 20800, 12800, 'MID', 0, 0),
  ('2-7', 'Sector 2-7', 2, 20800, 12800, 'MID', 0, 0),
  ('2-8', 'Sector 2-8', 2, 20800, 12800, 'MID', 0, 0),
  ('3-1', 'Sector 3-1', 3, 20800, 12800, 'LOW', 0, 0),
  ('3-2', 'Sector 3-2', 3, 20800, 12800, 'LOW', 0, 0),
  ('3-3', 'Sector 3-3', 3, 20800, 12800, 'LOW', 0, 0),
  ('3-4', 'Sector 3-4', 3, 20800, 12800, 'LOW', 0, 0),
  ('3-5', 'Sector 3-5', 3, 20800, 12800, 'MID', 0, 0),
  ('3-6', 'Sector 3-6', 3, 20800, 12800, 'MID', 0, 0),
  ('3-7', 'Sector 3-7', 3, 20800, 12800, 'MID', 0, 0),
  ('3-8', 'Sector 3-8', 3, 20800, 12800, 'MID', 0, 0),
  ('4-1', 'Sector 4-1', 0, 20800, 12800, 'MID', 0, 1),
  ('4-2', 'Sector 4-2', 0, 20800, 12800, 'MID', 0, 1),
  ('4-3', 'Sector 4-3', 0, 20800, 12800, 'MID', 0, 1),
  ('4-4', 'Sector 4-4', 0, 20800, 12800, 'HIGH', 0, 1),
  ('4-5', 'Sector 4-5', 0, 20800, 12800, 'HIGH', 0, 1);

-- Los portales se resiembran ENTEROS. El unico que habia (1-1 -> 1-2 de la .3) era
-- de una sola direccion: se iba al 1-2 y no habia vuelta. Borrar y rehacer deja el
-- grafo en un estado conocido en vez de parchear alrededor de un fallo.
DELETE FROM map_portal;

-- pos: el borde y el tercio salen del arte; la coordenada es esa posicion relativa
--      sobre 20800x12800, con 2000 de margen para que el portal no toque el borde.
-- target_pos: DERIVADA, no escrita a mano — se llega 1800 unidades por delante del
--      portal de vuelta, empujado hacia el centro del mapa. Asi no se puede llegar
--      encima de la puerta ni fuera del mapa, que son los dos fallos del legado.
INSERT INTO map_portal (map_id, pos_x, pos_y, target_map_id, target_pos_x, target_pos_y, is_visible, is_working)
SELECT o.id,  2824, 10800, d.id, 17068,  4506, 1, 1 FROM map o JOIN map d ON d.code='2-2' WHERE o.code='2-1'
UNION ALL SELECT o.id, 18800,  4015, d.id,  4380,  9895, 1, 1 FROM map o JOIN map d ON d.code='2-1' WHERE o.code='2-2'
UNION ALL SELECT o.id, 18800,  9537, d.id,  3892,  2860, 1, 1 FROM map o JOIN map d ON d.code='2-4' WHERE o.code='2-2'
UNION ALL SELECT o.id,  2311,  2000, d.id, 17113,  8907, 1, 1 FROM map o JOIN map d ON d.code='2-2' WHERE o.code='2-4'
UNION ALL SELECT o.id,  2000, 10290, d.id, 16906,  2860, 1, 1 FROM map o JOIN map d ON d.code='2-3' WHERE o.code='2-2'
UNION ALL SELECT o.id, 18488,  2000, d.id,  3633,  9533, 1, 1 FROM map o JOIN map d ON d.code='2-2' WHERE o.code='2-3'
UNION ALL SELECT o.id,  2000, 10800, d.id, 15933,  2951, 1, 1 FROM map o JOIN map d ON d.code='1-3' WHERE o.code='2-3'
UNION ALL SELECT o.id, 17461,  2000, d.id,  3594,  9964, 1, 1 FROM map o JOIN map d ON d.code='2-3' WHERE o.code='1-3'
UNION ALL SELECT o.id,  2000, 10800, d.id, 17152,  2839, 1, 1 FROM map o JOIN map d ON d.code='1-2' WHERE o.code='1-3'
UNION ALL SELECT o.id, 18745,  2000, d.id,  3594,  9964, 1, 1 FROM map o JOIN map d ON d.code='1-3' WHERE o.code='1-2'
UNION ALL SELECT o.id, 18800,  2000, d.id,  3614,  9745, 1, 1 FROM map o JOIN map d ON d.code='4-2' WHERE o.code='4-1'
UNION ALL SELECT o.id,  2000, 10541, d.id, 17205,  2835, 1, 1 FROM map o JOIN map d ON d.code='4-1' WHERE o.code='4-2'
UNION ALL SELECT o.id, 17461, 10800, d.id, 15933,  2951, 1, 1 FROM map o JOIN map d ON d.code='1-4' WHERE o.code='1-3'
UNION ALL SELECT o.id, 17461,  2000, d.id, 15933,  9848, 1, 1 FROM map o JOIN map d ON d.code='1-3' WHERE o.code='1-4'
UNION ALL SELECT o.id,  2000,  2000, d.id, 17205,  9964, 1, 1 FROM map o JOIN map d ON d.code='1-1' WHERE o.code='1-2'
UNION ALL SELECT o.id, 18800, 10800, d.id,  3594,  2835, 1, 1 FROM map o JOIN map d ON d.code='1-2' WHERE o.code='1-1'
UNION ALL SELECT o.id, 18232, 10800, d.id,  3594,  2835, 1, 1 FROM map o JOIN map d ON d.code='4-3' WHERE o.code='4-2'
UNION ALL SELECT o.id,  2000,  2000, d.id, 16662,  9918, 1, 1 FROM map o JOIN map d ON d.code='4-2' WHERE o.code='4-3'
UNION ALL SELECT o.id,  2000,  6776, d.id, 17001,  6695, 1, 1 FROM map o JOIN map d ON d.code='1-4' WHERE o.code='4-1'
UNION ALL SELECT o.id, 18800,  6776, d.id,  3798,  6695, 1, 1 FROM map o JOIN map d ON d.code='4-1' WHERE o.code='1-4'
UNION ALL SELECT o.id, 17975, 10800, d.id,  3651,  9323, 1, 1 FROM map o JOIN map d ON d.code='4-3' WHERE o.code='4-1'
UNION ALL SELECT o.id,  2000, 10039, d.id, 16418,  9895, 1, 1 FROM map o JOIN map d ON d.code='4-1' WHERE o.code='4-3'
UNION ALL SELECT o.id, 18745, 10800, d.id,  3594,  2835, 1, 1 FROM map o JOIN map d ON d.code='1-4' WHERE o.code='1-2'
UNION ALL SELECT o.id,  2000,  2000, d.id, 17152,  9960, 1, 1 FROM map o JOIN map d ON d.code='1-2' WHERE o.code='1-4'
UNION ALL SELECT o.id, 18800,  6274, d.id, 10323,  3799, 1, 1 FROM map o JOIN map d ON d.code='3-4' WHERE o.code='4-3'
UNION ALL SELECT o.id, 10271,  2000, d.id, 17000,  6300, 1, 1 FROM map o JOIN map d ON d.code='4-3' WHERE o.code='3-4'
UNION ALL SELECT o.id,  2311, 10800, d.id, 17204,  2841, 1, 1 FROM map o JOIN map d ON d.code='3-4' WHERE o.code='3-3'
UNION ALL SELECT o.id, 18800,  2007, d.id,  3892,  9939, 1, 1 FROM map o JOIN map d ON d.code='3-3' WHERE o.code='3-4'
UNION ALL SELECT o.id, 17975, 10800, d.id, 17148,  3475, 1, 1 FROM map o JOIN map d ON d.code='3-2' WHERE o.code='3-3'
UNION ALL SELECT o.id, 18800,  2760, d.id, 16418,  9895, 1, 1 FROM map o JOIN map d ON d.code='3-3' WHERE o.code='3-2'
UNION ALL SELECT o.id, 17975, 10800, d.id,  3595,  2841, 1, 1 FROM map o JOIN map d ON d.code='3-4' WHERE o.code='1-4'
UNION ALL SELECT o.id,  2000,  2007, d.id, 16418,  9895, 1, 1 FROM map o JOIN map d ON d.code='1-4' WHERE o.code='3-4'
UNION ALL SELECT o.id, 18800, 10800, d.id,  3651,  3475, 1, 1 FROM map o JOIN map d ON d.code='3-2' WHERE o.code='3-4'
UNION ALL SELECT o.id,  2000,  2760, d.id, 17205,  9964, 1, 1 FROM map o JOIN map d ON d.code='3-4' WHERE o.code='3-2'
UNION ALL SELECT o.id, 18800, 10800, d.id,  3595,  2841, 1, 1 FROM map o JOIN map d ON d.code='3-1' WHERE o.code='3-2'
UNION ALL SELECT o.id,  2000,  2007, d.id, 17205,  9964, 1, 1 FROM map o JOIN map d ON d.code='3-2' WHERE o.code='3-1'
UNION ALL SELECT o.id, 18800, 10541, d.id, 17205,  2835, 1, 1 FROM map o JOIN map d ON d.code='2-4' WHERE o.code='2-3'
UNION ALL SELECT o.id, 18800,  2000, d.id, 17185,  9745, 1, 1 FROM map o JOIN map d ON d.code='2-3' WHERE o.code='2-4'
UNION ALL SELECT o.id,  2311, 10800, d.id,  3646,  2839, 1, 1 FROM map o JOIN map d ON d.code='3-3' WHERE o.code='2-4'
UNION ALL SELECT o.id,  2054,  2000, d.id,  3892,  9939, 1, 1 FROM map o JOIN map d ON d.code='2-4' WHERE o.code='3-3'
UNION ALL SELECT o.id, 10271, 10800, d.id, 10323,  3799, 1, 1 FROM map o JOIN map d ON d.code='4-2' WHERE o.code='2-4'
UNION ALL SELECT o.id, 10271,  2000, d.id, 10323,  9000, 1, 1 FROM map o JOIN map d ON d.code='2-4' WHERE o.code='4-2'
UNION ALL SELECT o.id,  2567, 10800, d.id, 17097,  4098, 1, 1 FROM map o JOIN map d ON d.code='2-6' WHERE o.code='2-8'
UNION ALL SELECT o.id, 18800,  3513, d.id,  4136,  9918, 1, 1 FROM map o JOIN map d ON d.code='2-8' WHERE o.code='2-6'
UNION ALL SELECT o.id, 18488, 10800, d.id, 16906,  2860, 1, 1 FROM map o JOIN map d ON d.code='2-7' WHERE o.code='2-8'
UNION ALL SELECT o.id, 18488,  2000, d.id, 16906,  9939, 1, 1 FROM map o JOIN map d ON d.code='2-8' WHERE o.code='2-7'
UNION ALL SELECT o.id,  2311, 10800, d.id,  3892,  2860, 1, 1 FROM map o JOIN map d ON d.code='2-5' WHERE o.code='2-6'
UNION ALL SELECT o.id,  2311,  2000, d.id,  3892,  9939, 1, 1 FROM map o JOIN map d ON d.code='2-6' WHERE o.code='2-5'
UNION ALL SELECT o.id, 18800,  2007, d.id,  3892,  9939, 1, 1 FROM map o JOIN map d ON d.code='2-7' WHERE o.code='2-5'
UNION ALL SELECT o.id,  2311, 10800, d.id, 17204,  2841, 1, 1 FROM map o JOIN map d ON d.code='2-5' WHERE o.code='2-7'
UNION ALL SELECT o.id, 18800,  2000, d.id,  3717,  8496, 1, 1 FROM map o JOIN map d ON d.code='2-5' WHERE o.code='4-4'
UNION ALL SELECT o.id,  2000,  9035, d.id, 17205,  2835, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='2-5'
UNION ALL SELECT o.id,  4622, 10800, d.id, 15692,  2977, 1, 1 FROM map o JOIN map d ON d.code='1-8' WHERE o.code='1-6'
UNION ALL SELECT o.id, 17204,  2000, d.id,  6054,  9709, 1, 1 FROM map o JOIN map d ON d.code='1-6' WHERE o.code='1-8'
UNION ALL SELECT o.id, 16434, 10800, d.id,  6744,  3188, 1, 1 FROM map o JOIN map d ON d.code='1-5' WHERE o.code='1-6'
UNION ALL SELECT o.id,  5392,  2000, d.id, 14979,  9739, 1, 1 FROM map o JOIN map d ON d.code='1-6' WHERE o.code='1-5'
UNION ALL SELECT o.id, 18800,  6525, d.id,  3799,  6234, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='1-5'
UNION ALL SELECT o.id,  2000,  6190, d.id, 17000,  6498, 1, 1 FROM map o JOIN map d ON d.code='1-5' WHERE o.code='4-4'
UNION ALL SELECT o.id, 17204, 10800, d.id,  6054,  3090, 1, 1 FROM map o JOIN map d ON d.code='1-7' WHERE o.code='1-8'
UNION ALL SELECT o.id,  4622,  2000, d.id, 15692,  9822, 1, 1 FROM map o JOIN map d ON d.code='1-8' WHERE o.code='1-7'
UNION ALL SELECT o.id,  5392, 10800, d.id, 15692,  2977, 1, 1 FROM map o JOIN map d ON d.code='1-7' WHERE o.code='1-5'
UNION ALL SELECT o.id, 17204,  2000, d.id,  6744,  9611, 1, 1 FROM map o JOIN map d ON d.code='1-5' WHERE o.code='1-7'
UNION ALL SELECT o.id, 14123, 10800, d.id,  3796,  6811, 1, 1 FROM map o JOIN map d ON d.code='4-5' WHERE o.code='1-5'
UNION ALL SELECT o.id,  2000,  6924, d.id, 12960,  9425, 1, 1 FROM map o JOIN map d ON d.code='1-5' WHERE o.code='4-5'
UNION ALL SELECT o.id, 18453, 10800, d.id,  3717,  4302, 1, 1 FROM map o JOIN map d ON d.code='3-5' WHERE o.code='4-4'
UNION ALL SELECT o.id,  2000,  3764, d.id, 16873,  9936, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='3-5'
UNION ALL SELECT o.id, 18800, 10039, d.id,  3651,  9323, 1, 1 FROM map o JOIN map d ON d.code='3-7' WHERE o.code='3-5'
UNION ALL SELECT o.id,  2000, 10039, d.id, 17148,  9323, 1, 1 FROM map o JOIN map d ON d.code='3-5' WHERE o.code='3-7'
UNION ALL SELECT o.id, 18800, 10039, d.id,  4905,  2955, 1, 1 FROM map o JOIN map d ON d.code='3-8' WHERE o.code='3-7'
UNION ALL SELECT o.id,  3380,  2000, d.id, 17148,  9323, 1, 1 FROM map o JOIN map d ON d.code='3-7' WHERE o.code='3-8'
UNION ALL SELECT o.id,  3851, 10800, d.id,  3594,  2835, 1, 1 FROM map o JOIN map d ON d.code='3-6' WHERE o.code='3-5'
UNION ALL SELECT o.id,  2000,  2000, d.id,  5345,  9796, 1, 1 FROM map o JOIN map d ON d.code='3-5' WHERE o.code='3-6'
UNION ALL SELECT o.id, 18800,  9286, d.id,  3702,  8701, 1, 1 FROM map o JOIN map d ON d.code='3-8' WHERE o.code='3-6'
UNION ALL SELECT o.id,  2000,  9286, d.id, 17097,  8701, 1, 1 FROM map o JOIN map d ON d.code='3-6' WHERE o.code='3-8'
UNION ALL SELECT o.id, 10453,  2000, d.id, 17043,  7888, 1, 1 FROM map o JOIN map d ON d.code='2-5' WHERE o.code='4-5'
UNION ALL SELECT o.id, 18800,  8282, d.id, 10431,  3799, 1, 1 FROM map o JOIN map d ON d.code='4-5' WHERE o.code='2-5'
UNION ALL SELECT o.id, 10453, 10800, d.id, 13172,  3334, 1, 1 FROM map o JOIN map d ON d.code='3-5' WHERE o.code='4-5'
UNION ALL SELECT o.id, 14380,  2000, d.id, 10431,  9000, 1, 1 FROM map o JOIN map d ON d.code='4-5' WHERE o.code='3-5'
UNION ALL SELECT o.id, 10400,  6400, d.id,  9014,  3611, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='4-1'
UNION ALL SELECT o.id, 10400,  6400, d.id, 10368,  3799, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='4-2'
UNION ALL SELECT o.id, 10400,  6400, d.id, 11636,  3642, 1, 1 FROM map o JOIN map d ON d.code='4-4' WHERE o.code='4-3'
UNION ALL SELECT o.id,  8213,  2000, d.id, 10400,  6400, 1, 1 FROM map o JOIN map d ON d.code='4-1' WHERE o.code='4-4'
UNION ALL SELECT o.id, 10346,  2000, d.id, 10400,  6400, 1, 1 FROM map o JOIN map d ON d.code='4-2' WHERE o.code='4-4'
UNION ALL SELECT o.id, 12373,  2000, d.id, 10400,  6400, 1, 1 FROM map o JOIN map d ON d.code='4-3' WHERE o.code='4-4';

INSERT INTO schema_migration (version) VALUES ('2026.08.26.1');
COMMIT;
