-- Rollback de 2026.08.25.8 — la Phoenix vuelve a su bodega de 100.
-- Ojo: con 100, las cajas del Ferox y del Skarnox vuelven a no caber.

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE ship_catalog SET cargo_capacity = 100 WHERE code = 'phoenix';

DELETE FROM schema_migration WHERE version = '2026.08.25.8';
