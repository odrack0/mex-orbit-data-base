-- 2026.08.28.1 — los diales de la relevancia por rango.
--
-- Hoy el game server manda TODO lo del mapa a TODOS: 54 NPCs, sus movimientos y
-- cada caja, a cada jugador, esten donde esten. Es la razon de que el minimapa
-- muestre el sector entero, y no escala: con 29 mapas y varios jugadores por
-- mapa, el ancho de banda crece con el producto y no con lo que se ve.
--
-- La spec del protocolo (protocolo-v1.md §relevancia por rango) ya fijo los
-- valores iniciales y dijo que son calibrables en BD; estas son esas filas.
-- Portales, estacion y POIs NO entran por aqui: viajan completos en EnterMap
-- porque son mobiliario del mapa, no entidades.
--
-- La histeresis no viene del legado: alli el umbral era uno solo y un jugador
-- parado justo en el borde generaba un spawn y un despawn CADA tick (12 pares
-- por segundo y por entidad). Con la banda, se entra a 2000 y no se sale hasta
-- 2200.
--
-- Requiere: mex-orbit-game-server con la relevancia por rango.

START TRANSACTION;

INSERT INTO server_setting (setting_key, value, value_type, min_value, max_value, unit, description) VALUES
  ('render_range_entities',       '2000', 'INT', 500, 20000, 'u',
   'a que distancia el cliente empieza a recibir naves y NPCs'),
  ('render_range_objects',        '1250', 'INT', 250, 20000, 'u',
   'a que distancia el cliente empieza a recibir cajas'),
  ('render_range_hysteresis_pct', '10',   'INT', 0,   100,   '%',
   'margen extra para SALIR de rango; 0 = un solo umbral, como el server legado')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO schema_migration (version) VALUES ('2026.08.28.1');

COMMIT;
