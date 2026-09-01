-- Vuelve la posicion a sin signo. Una nave que quedo en negativo se trae al 0:
-- sin este paso el MODIFY a UNSIGNED reventaria (o la envolveria a 4 mil millones).
START TRANSACTION;

UPDATE player_ship_state SET pos_x = GREATEST(pos_x, 0), pos_y = GREATEST(pos_y, 0);

ALTER TABLE player_ship_state
  MODIFY pos_x INT UNSIGNED NOT NULL,
  MODIFY pos_y INT UNSIGNED NOT NULL;

DELETE FROM schema_migration WHERE version = '2026.09.01.1';
COMMIT;
