-- Rollback de 2026.08.25.3 — quita el portal del 1-1 y su mapa destino.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

DELETE p FROM map_portal p
JOIN map o ON o.id = p.map_id
JOIN map d ON d.id = p.target_map_id
WHERE o.code = '1-1' AND d.code = '1-2';

DELETE FROM map WHERE code = '1-2';

DELETE FROM schema_migration WHERE version = '2026.08.25.3';
