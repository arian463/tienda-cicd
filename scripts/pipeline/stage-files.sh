
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEPLOY_PATH="${DEPLOY_PATH:-$HOME/tienda-staging}"

mkdir -p "$DEPLOY_PATH"
for dir in deploy monitoring scripts; do
  rm -rf "${DEPLOY_PATH:?}/$dir"
  cp -r "$ROOT/$dir" "$DEPLOY_PATH/$dir"
done
echo "Archivos de despliegue copiados a $DEPLOY_PATH"

# Deja la ruta disponible para los siguientes pasos del workflow
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "DEPLOY_PATH=$DEPLOY_PATH" >> "$GITHUB_ENV"
fi