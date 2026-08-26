-- 2026.08.26.2 — llegar ENCIMA del portal, y el directorio de servidores por mapa.
--
-- 1) La llegada pasa a ser la posicion EXACTA del portal de vuelta, no 1800
--    unidades por delante. Aquello se hizo para que aterrizar no re-disparase
--    el salto; con el salto atado a una TECLA eso ya no puede pasar, y llegar
--    encima es lo que hacia el original (`player.SetPosition(TargetPosition)`).
--
-- 2) `map_server` dice DONDE vive cada mapa. Hoy todos apuntan al mismo sitio,
--    pero el salto negocia igual: si el handoff solo se ejecutara al partir los
--    mapas, seria un camino sin probar hasta el peor momento para descubrirlo.
--    Partir manana es cambiar filas de esta tabla.

START TRANSACTION;

-- La llegada se DERIVA del portal de vuelta: una consulta, no 84 numeros a mano.
UPDATE map_portal p
  JOIN map_portal v ON v.map_id = p.target_map_id AND v.target_map_id = p.map_id
SET p.target_pos_x = v.pos_x, p.target_pos_y = v.pos_y;

CREATE TABLE map_server (
  map_id  BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  host    VARCHAR(128) NOT NULL COMMENT 'host o ip del game server que sirve este mapa',
  port    SMALLINT UNSIGNED NOT NULL,
  is_tls  TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'ws:// en dev, wss:// en prod',
  CONSTRAINT fk_map_server_map FOREIGN KEY (map_id) REFERENCES map(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='donde vive cada mapa: el directorio del salto entre servidores';

-- Todos al mismo, de momento. La gracia es que el codigo no lo sabe.
INSERT INTO map_server (map_id, host, port, is_tls)
SELECT id, '127.0.0.1', 5200, 0 FROM map;

INSERT INTO schema_migration (version) VALUES ('2026.08.26.2');
COMMIT;
