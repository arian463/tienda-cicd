
wait_healthy() {
  local port="$1" version="$2" attempt
  for attempt in $(seq 1 30); do
    if curl -fsS --max-time 3 "http://127.0.0.1:${port}/health" 2>/dev/null | grep -q "\"version\":\"${version}\""; then
      echo "Salud OK (versión ${version}, intento ${attempt})"
      return 0
    fi
    sleep 2
  done
  return 1
}
