
set -uo pipefail
export LC_ALL=C

BASE_URL="${BASE_URL:?Falta BASE_URL}"
N="${N:-50}"
MAX_P95_MS="${MAX_P95_MS:-300}"
MIN_AVAIL="${MIN_AVAIL:-99}"

ok=0
times=()
for _ in $(seq 1 "$N"); do
  out="$(curl -s -o /dev/null -w '%{http_code} %{time_total}' --max-time 10 "$BASE_URL/products" || true)"
  code="${out%% *}"
  t="${out##* }"
  [ "$code" = "200" ] && ok=$((ok + 1))
  times+=("$t")
done

avail="$(awk -v ok="$ok" -v n="$N" 'BEGIN { printf "%.2f", ok * 100 / n }')"
p95_ms="$(printf '%s\n' "${times[@]}" | sort -n | awk -v n="$N" '
  BEGIN { idx = int(n * 0.95); if (idx < n * 0.95) idx++ }
  NR == idx { printf "%.0f", $1 * 1000 }')"

echo "Peticiones: $N | Correctas: $ok | Disponibilidad: ${avail}% (mínimo ${MIN_AVAIL}%)"
echo "Latencia p95: ${p95_ms} ms (máximo ${MAX_P95_MS} ms)"

failed=0
if ! awk -v a="$avail" -v m="$MIN_AVAIL" 'BEGIN { exit !(a >= m) }'; then
  echo "FAIL  disponibilidad por debajo del objetivo"
  failed=1
fi
if [ -z "$p95_ms" ] || [ "$p95_ms" -gt "$MAX_P95_MS" ]; then
  echo "FAIL  latencia p95 por encima del objetivo"
  failed=1
fi

if [ "$failed" -ne 0 ]; then
  echo "Chequeo de SLA FALLÓ"
  exit 1
fi
echo "Chequeo de SLA OK"
