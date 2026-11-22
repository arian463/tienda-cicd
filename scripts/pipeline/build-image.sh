
set -euo pipefail

: "${IMAGE:?Falta la variable IMAGE}"
: "${TAG:?Falta la variable TAG}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# En GitHub Actions se vincula la imagen con el repositorio sin esta etiqueta,
# GHCR puede rechazar el push de una imagen nueva con "denied".
LABEL_ARGS=()
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
  LABEL_ARGS=(--label "org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY}")
fi

echo "Construyendo $IMAGE:$TAG"
docker build "${LABEL_ARGS[@]}" --build-arg APP_VERSION="$TAG" -t "$IMAGE:$TAG" "$ROOT/app"

echo "Publicando $IMAGE:$TAG"
docker push "$IMAGE:$TAG"