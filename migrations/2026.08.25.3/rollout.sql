-- ============================================================
-- Migración 2026.08.25.3 — el portal del 1-1 (E2, después del gate)
-- El portal es mobiliario del mapa y su posición es DATO, no una constante del
-- cliente: vive en map_portal y viaja completo en EnterMap.
-- map_portal.target_map_id es FK real ("el destino existe por construcción"),
-- así que el destino se crea aquí: Umbra 1-2 queda declarado como mapa vecino,
-- sin estación ni spawns todavía. El salto en sí llega en E3; por ahora el
-- portal se ve, se vuela hacia él y aparece en el minimapa.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

INSERT INTO map (code, display_name, faction_id, bounds_max_x, bounds_max_y, zone_tier, is_starter, is_pvp)
VALUES ('1-2', 'Umbra 1-2', 1, 20800, 12800, 'LOW', 0, 0);

-- borde derecho del 1-1, a media altura: la salida del sector, lejos de la base
INSERT INTO map_portal (map_id, pos_x, pos_y, target_map_id, target_pos_x, target_pos_y, is_visible, is_working)
SELECT o.id, 18800, 6400, d.id, 2000, 6400, 1, 1
FROM map o JOIN map d ON d.code = '1-2'
WHERE o.code = '1-1';

INSERT INTO schema_migration (version) VALUES ('2026.08.25.3');
