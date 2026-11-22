
set -euo pipefail

: "${IMAGE:?Falta la variable IMAGE}"
: "${TAG:?Falta la variable TAG}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Construyendo $IMAGE:$TAG"
docker build --build-arg APP_VERSION="$TAG" -t "$IMAGE:$TAG" "$ROOT/app"

echo "Publicando $IMAGE:$TAG"
docker push "$IMAGE:$TAG"
