-- ============================================================
-- Migración 2026.08.25.6 — la IA de los NPCs necesita dos cosas de la BD
--
-- 1) El Ferox se enciende. `is_aggressive` existía desde la migración .1 pero
--    ningún NPC lo tenía en 1, porque el server no leía el dial. Ahora que la
--    IA existe, el cazador caza: es el único agresivo del 1-1, coherente con su
--    identidad (velocidad 420, la mayor del mapa). Los otros cuatro siguen
--    pasivos — pero pasivo NO es inofensivo: al recibir un golpe devuelven el
--    fuego (el ReceiveAttack del server legado).
--
-- 2) Una razón nueva en el ledger. Al morir, la bodega VOLANTE del jugador se
--    queda en el sitio dentro de una caja (transferencia, no destrucción:
--    guidelines §7), y esa salida hay que asentarla. El almacén de la base no
--    se toca — para eso está separado del hold desde el día uno.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE npc_catalog SET is_aggressive = 1 WHERE code = 'ferox';

ALTER TABLE economy_ledger
  MODIFY COLUMN reason ENUM('NPC_KILL','CARGO_PICKUP','CARGO_UNLOAD','REFINE_IN',
                            'REFINE_OUT','NPC_SALE','REPAIR','ADMIN','CARGO_LOST') NOT NULL;

INSERT INTO schema_migration (version) VALUES ('2026.08.25.6');
