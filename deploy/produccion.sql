-- Ajustes que dependen del ENTORNO, no del esquema. Por eso viven aqui y no en
-- una migracion: una migracion describe la forma de la base y debe dar lo mismo
-- en el portatil de cualquiera; esto describe una maquina concreta.
--
--   mysql astrion < deploy/produccion.sql
--
-- Es idempotente: correrlo dos veces no hace dano, y hay que correrlo despues de
-- CADA migracion nueva que toque `map` o `map_server`.

-- Donde vive cada mapa. La migracion los siembra en 127.0.0.1:5200 sin TLS, que
-- es lo correcto en dev y una bomba en produccion: el juego entraria bien y
-- fallaria justo AL SALTAR de sector, porque el host del salto sale de aqui y no
-- del que uso el cliente para entrar. Es el fallo mas caro de diagnosticar de
-- todo el despliegue, porque no aparece hasta el segundo mapa.
--
-- El puerto es 443 y no 5210: el cliente compone `wss://host:puerto/ws` y quien
-- termina el TLS es nginx. El 5210 es interno y nadie de fuera lo ve.
UPDATE map_server SET host = 'astrion-gs.turname.mx', port = 443, is_tls = 1;

-- Y que no quede ninguno apuntando a la maquina de desarrollo.
SELECT CONCAT('mapas apuntando a dev: ', COUNT(*)) AS revision
FROM map_server WHERE host IN ('127.0.0.1', 'localhost') OR is_tls = 0;
