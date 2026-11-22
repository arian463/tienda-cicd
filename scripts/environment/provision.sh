
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENVIRONMENT="${ENVIRONMENT:-staging}"
MIN_FREE_KB=$((1024 * 1024)) # 1 GB

echo "Verificando requisitos del servidor"
command -v docker >/dev/null || { echo "ERROR: Docker no está instalado"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: falta el plugin Docker Compose v2"; exit 1; }
command -v curl >/dev/null || { echo "ERROR: curl no está instalado"; exit 1; }

free_kb="$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')"
if [ "$free_kb" -lt "$MIN_FREE_KB" ]; then
  echo "ERROR: menos de 1 GB libre en $ROOT"
  exit 1
fi

echo " Generando archivo de configuración "
if [ ! -f "$ROOT/.env" ]; then
  sed "s/__ENVIRONMENT__/$ENVIRONMENT/" "$ROOT/scripts/environment/.env.example" > "$ROOT/.env"
  chmod 600 "$ROOT/.env"
  echo "Creado .env para $ENVIRONMENT"
else
  echo ".env ya existe, no se modifica"
fi

echo "== Validando variables =="
set -a
# shellcheck disable=SC1091
source "$ROOT/.env"
set +a
for var in ENVIRONMENT NODE_ENV APP_PORT PORT; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: falta la variable $var en .env"
    exit 1
  fi
done

echo "Entorno $ENVIRONMENT listo en $ROOT"
