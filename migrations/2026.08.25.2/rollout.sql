-- ============================================================
-- Migración 2026.08.25.2 — stats jugables del Vex para el slice (E2/I5)
-- El seed inicial (8000 hp / 4000 escudo) daba un TTK de >3 minutos con el
-- ION-1: injugable. Valores provisionales hasta la pasada de balanceo (E6).
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog
SET max_hp = 800, max_shield = 400
WHERE code = 'vex';

INSERT INTO schema_migration (version) VALUES ('2026.08.25.2');
