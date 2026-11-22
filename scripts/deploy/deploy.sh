
set -euo pipefail

: "${IMAGE:?Falta la variable IMAGE}"
: "${TAG:?Falta la variable TAG}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/scripts/deploy/lib.sh"

COMPOSE=(docker compose --env-file .env -f deploy/docker-compose.yml)
APP_PORT="$(grep -E '^APP_PORT=' .env | cut -d= -f2)"
PREV_TAG=""
[ -f .current_tag ] && PREV_TAG="$(cat .current_tag)"

export IMAGE TAG
echo "Desplegando $IMAGE:$TAG (versión anterior: ${PREV_TAG:-ninguna})"

"${COMPOSE[@]}" pull
"${COMPOSE[@]}" up -d --remove-orphans

if wait_healthy "$APP_PORT" "$TAG"; then
  [ -n "$PREV_TAG" ] && [ "$PREV_TAG" != "$TAG" ] && echo "$PREV_TAG" > .previous_tag
  echo "$TAG" > .current_tag
  echo "Despliegue de $TAG completado"
  exit 0
fi

echo "ERROR: la versión $TAG no respondió sana en 60 s"
"${COMPOSE[@]}" logs --tail=50 api || true
if [ -n "$PREV_TAG" ]; then
  echo "Iniciando rollback a $PREV_TAG"
  "$ROOT/scripts/deploy/rollback.sh" "$PREV_TAG" || true
else
  echo "No hay versión anterior a la cual volver"
fi
exit 1
