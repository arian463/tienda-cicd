
set -uo pipefail
export LC_ALL=C

BASE_URL="${BASE_URL:?Falta BASE_URL}"
EXPECTED_VERSION="${EXPECTED_VERSION:-}"
READ_ONLY="${READ_ONLY:-false}"
failed=0

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; failed=1; }
status() { curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$@" || true; }

#la API responde y está sana
code="$(status "$BASE_URL/health")"
if [ "$code" = "200" ]; then pass "GET /health = 200"; else fail "GET /health = $code"; fi

#Es la versión que se acaba de desplegar
if [ -n "$EXPECTED_VERSION" ]; then
  body="$(curl -s --max-time 10 "$BASE_URL/health" || true)"
  if echo "$body" | grep -q "\"version\":\"$EXPECTED_VERSION\""; then
    pass "versión desplegada = $EXPECTED_VERSION"
  else
    fail "versión desplegada distinta de $EXPECTED_VERSION (respuesta: $body)"
  fi
fi

#El catálogo tiene productos
body="$(curl -s --max-time 10 "$BASE_URL/products" || true)"
if echo "$body" | grep -q '"id"'; then pass "GET /products devuelve productos"; else fail "GET /products sin productos"; fi

#Un producto inexistente da 404
code="$(status "$BASE_URL/products/9999")"
if [ "$code" = "404" ]; then pass "GET /products/9999 = 404"; else fail "GET /products/9999 = $code"; fi

#Un pedido inválido es rechazado 
code="$(status -X POST -H 'content-type: application/json' -d '{"productId":1,"quantity":0}' "$BASE_URL/orders")"
if [ "$code" = "400" ]; then pass "POST /orders inválido = 400"; else fail "POST /orders inválido = $code"; fi

#Un pedido válido se crea 
if [ "$READ_ONLY" = "true" ]; then
  echo "SKIP  POST /orders válido (READ_ONLY=true)"
else
  code="$(status -X POST -H 'content-type: application/json' -d '{"productId":1,"quantity":1}' "$BASE_URL/orders")"
  if [ "$code" = "201" ]; then pass "POST /orders válido = 201"; else fail "POST /orders válido = $code"; fi
fi

#Las métricas están expuestas
body="$(curl -s --max-time 10 "$BASE_URL/metrics" || true)"
if echo "$body" | grep -q 'http_request_duration_seconds'; then pass "GET /metrics expone métricas"; else fail "GET /metrics sin métricas"; fi

if [ "$failed" -ne 0 ]; then
  echo "Smoke test FALLÓ"
  exit 1
fi
echo "Smoke test OK"
