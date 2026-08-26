-- ============================================================
-- Migración 2026.08.25.8 — la bodega de la Phoenix: 100 → 300
--
-- El problema no era la caja, era la proporción. Con bodega 100:
--   · Un Vex suelta 30-60, así que te llenas cada DOS muertes. El loop se
--     convertía en un ir y venir a la base en vez de en salir a cazar.
--   · Las cajas grandes ni cabían: el Ferox suelta hasta 180 y el Skarnox
--     hasta 240. La recogida parcial deja el resto en la caja, pero la caja
--     expira a los 150 s (guidelines §7) — o sea que lejos de la base el
--     sobrante se evaporaba.
--
-- Eso último choca de frente con el diseño: los materiales salen **única y
-- exclusivamente** de las cajas de carga de los aliens (§8), así que hacerlos
-- desaparecer por diseño manda una señal económica pésima.
--
-- Con 300, la caja MÁS grande del mapa (240 del Skarnox) cabe entera, y el
-- ritmo de viajes a la base queda así (por bodega llena):
--   Vex ~7 muertes · Vexor ~4 · Skarn ~3 · Ferox ~2 · Skarnox ~1,5
--
-- Referencia: en el DO clásico la nave inicial cargaba 100 y los Streuner
-- soltaban 10-20 — una proporción de 1:7. La nuestra era de 1:2.
--
-- La bodega es **identidad de la nave**, no un producto: no hay extensores de
-- slot (decisión cerrada de las guidelines). La progresión de capacidad llega
-- por dos vías ya diseñadas: naves mayores del roster de 9, y el **AMP-CRG**
-- (+% de bodega), que es crafteable y llega en E4.
--
-- Provisional hasta el balanceo de E6, como el resto de los números del slice.
-- ============================================================

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

UPDATE ship_catalog SET cargo_capacity = 300 WHERE code = 'phoenix';

INSERT INTO schema_migration (version) VALUES ('2026.08.25.8');
