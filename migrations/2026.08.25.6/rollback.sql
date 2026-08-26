-- Rollback de 2026.08.25.6 — el Ferox vuelve a ser pasivo y el ledger pierde
-- la razón CARGO_LOST. Ojo: si ya hay filas con esa razón, el MODIFY falla;
-- primero se borran (son asientos de muertes de prueba).

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET is_aggressive = 0 WHERE code = 'ferox';

DELETE FROM economy_ledger WHERE reason = 'CARGO_LOST';

ALTER TABLE economy_ledger
  MODIFY COLUMN reason ENUM('NPC_KILL','CARGO_PICKUP','CARGO_UNLOAD','REFINE_IN',
                            'REFINE_OUT','NPC_SALE','REPAIR','ADMIN') NOT NULL;

DELETE FROM schema_migration WHERE version = '2026.08.25.6';
