
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "== 1/4 Instalando dependencias =="
(cd "$ROOT/app" && npm ci)

echo "== 2/4 Pruebas unitarias =="
(cd "$ROOT/app" && npm test)

echo "== 3/4 Auditoría de dependencias (falla con severidad alta o crítica) =="
(cd "$ROOT/app" && npm audit --omit=dev --audit-level=high)

echo "== 4/4 Validando sintaxis de los scripts de shell =="
while IFS= read -r script; do
  bash -n "$script"
  echo "OK  ${script#"$ROOT"/}"
done < <(find "$ROOT/scripts" -name '*.sh' | sort)

echo "CI completado correctamente"
