#!/usr/bin/env bash
# Corredor de migraciones para Linux. El de PowerShell aplica UNA version; este
# aplica TODAS las que falten, en orden, y por eso existe: en produccion nadie va
# a teclear treinta versiones a mano sin saltarse una.
#
#   DB=astrion ./tools/migrate.sh              aplica lo que falte
#   DB=astrion ./tools/migrate.sh --estado     solo dice que falta, no toca nada
#   DB=astrion ./tools/migrate.sh --hasta 2026.08.26.2
#
# El orden lo da el NOMBRE de la carpeta, que es una fecha con secuencia
# (2026.08.26.2). `sort -V` las ordena bien incluso cuando el ultimo numero pasa
# de 9, que es donde un `sort` normal se equivocaria.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${DB:-astrion}"
MYSQL=(mysql --protocol=socket -u root)
SOLO_ESTADO=0
HASTA=""

while [ $# -gt 0 ]; do
  case "$1" in
    --estado) SOLO_ESTADO=1; shift ;;
    --hasta) HASTA="$2"; shift 2 ;;
    *) echo "argumento desconocido: $1" >&2; exit 2 ;;
  esac
done

"${MYSQL[@]}" -e "CREATE DATABASE IF NOT EXISTS \`$DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

# `schema_migration` la crea la primera migracion. Si aun no existe, no hay
# ninguna aplicada — que es distinto de "fallo la consulta", asi que se distingue.
if "${MYSQL[@]}" -N -B "$DB" -e "SHOW TABLES LIKE 'schema_migration';" | grep -q .; then
  aplicadas="$("${MYSQL[@]}" -N -B "$DB" -e "SELECT version FROM schema_migration;")"
else
  aplicadas=""
fi

pendientes=()
for dir in $(ls -1 "$RAIZ/migrations" | sort -V); do
  [ -f "$RAIZ/migrations/$dir/rollout.sql" ] || continue
  grep -qxF "$dir" <<<"$aplicadas" && continue
  pendientes+=("$dir")
  [ -n "$HASTA" ] && [ "$dir" = "$HASTA" ] && break
done

echo "base: $DB · aplicadas: $(grep -c . <<<"$aplicadas" || true) · pendientes: ${#pendientes[@]}"
if [ ${#pendientes[@]} -eq 0 ]; then echo "nada que hacer"; exit 0; fi
printf '  %s\n' "${pendientes[@]}"
[ "$SOLO_ESTADO" = "1" ] && exit 0

for v in "${pendientes[@]}"; do
  printf 'aplicando %s ... ' "$v"
  # Sin `set -e` de por medio: se quiere el mensaje de MySQL, no un corte seco.
  if ! "${MYSQL[@]}" "$DB" < "$RAIZ/migrations/$v/rollout.sql"; then
    echo "FALLO en $v — se para aqui; las anteriores quedan aplicadas" >&2
    exit 1
  fi
  echo "ok"
done
echo "MIGRACIONES OK"
