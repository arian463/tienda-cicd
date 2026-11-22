
set -euo pipefail

: "${IMAGE:?Falta la variable IMAGE}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/scripts/deploy/lib.sh"

TARGET_TAG="${1:-}"
if [ -z "$TARGET_TAG" ] && [ -f .previous_tag ]; then
  TARGET_TAG="$(cat .previous_tag)"
fi
if [ -z "$TARGET_TAG" ]; then
  echo "ERROR: no hay versión anterior registrada ni se indicó una etiqueta"
  exit 1
fi

COMPOSE=(docker compose --env-file .env -f deploy/docker-compose.yml)
APP_PORT="$(grep -E '^APP_PORT=' .env | cut -d= -f2)"

export IMAGE
export TAG="$TARGET_TAG"
echo "Rollback a $IMAGE:$TARGET_TAG"

"${COMPOSE[@]}" up -d --remove-orphans

if wait_healthy "$APP_PORT" "$TARGET_TAG"; then
  echo "$TARGET_TAG" > .current_tag
  echo "Rollback completado"
else
  echo "ERROR: el rollback a $TARGET_TAG tampoco respondió sano requiere intervención manual"
  exit 1
fi
