-- ============================================================
-- Migración 2026.09.02.2 — Renombre TEMPORAL: drony → aci-01
--
-- El nombre definitivo de la décima especie no está decidido; mientras
-- tanto vive como `aci-01` (código, especie y nombre visible) para que el
-- placeholder no se filtre a ningún sitio. El cliente busca su JSON y su
-- malla por el code, así que este cambio va de la mano de
-- data/npcs/aci-01.json + assets/npcs/aci-01.glb. Requiere reiniciar el
-- game server (carga el catálogo al arrancar).
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET code = 'aci-01', display_name = 'ACI-01', species = 'aci-01' WHERE code = 'drony';

INSERT INTO schema_migration (version) VALUES ('2026.09.02.2');
