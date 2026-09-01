-- 2026.09.01.1 — la posicion de la nave va CON SIGNO: zona radiactiva por los cuatro lados.
--
-- Mas alla del limite del mapa la nave sigue volando (hasta 1000 u, el margen de
-- la zona radiactiva) y paga por segundo. Por el lado del 0 eso es NEGATIVO, y
-- `pos_x`/`pos_y` eran INT UNSIGNED: el write-behind de una nave en (-500, y)
-- habria reventado, y el login la habria puesto en cualquier sitio menos donde
-- estaba. El mobiliario (map_station, map_portal) se queda sin signo: un portal
-- o una base nunca estan fuera del mapa.
--
-- Lo requieren: mex-orbit-game-server y mex-orbit-client a partir del 1-sep-2026
-- (coordenadas `sint` en el protocolo). Los tres se despliegan JUNTOS.

START TRANSACTION;

ALTER TABLE player_ship_state
  MODIFY pos_x INT NOT NULL COMMENT 'con signo: negativo = zona radiactiva por el lado del 0',
  MODIFY pos_y INT NOT NULL COMMENT 'con signo: negativo = zona radiactiva por el lado del 0';

INSERT INTO schema_migration (version) VALUES ('2026.09.01.1');
COMMIT;
