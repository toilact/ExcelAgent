#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
launcher_pid=""
cleanup() {
  [[ -n $launcher_pid ]] && kill "$launcher_pid" 2>/dev/null || true
  [[ -n $launcher_pid ]] && wait "$launcher_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

if curl -fsS --connect-timeout 1 --max-time 1 \
  http://127.0.0.1:8000/api/health >/dev/null 2>&1 || \
  curl -fsS --connect-timeout 1 --max-time 1 \
    http://127.0.0.1:5173/ >/dev/null 2>&1; then
  echo "Development smoke test requires free ports 8000 and 5173" >&2
  exit 1
fi

"$repo_root/scripts/dev" --no-open &
launcher_pid=$!
health=""
ui_ready=0
readiness_deadline=$((SECONDS + 30))
while [[ $SECONDS -lt $readiness_deadline ]]; do
  health=$(curl -fsS --connect-timeout 1 --max-time 1 \
    http://127.0.0.1:8000/api/health 2>/dev/null || true)
  if [[ $health == *'"service":"excel-agent-api"'* ]] && \
    curl -fsS --connect-timeout 1 --max-time 1 \
      http://127.0.0.1:5173/ >/dev/null 2>&1; then
    if kill -0 "$launcher_pid" 2>/dev/null; then
      ui_ready=1
      break
    fi
    break
  fi
  kill -0 "$launcher_pid" 2>/dev/null || break
  [[ $SECONDS -lt $readiness_deadline ]] || break
  sleep 0.25
done

[[ $ui_ready -eq 1 ]] || { echo "Development smoke test timed out" >&2; exit 1; }
[[ $health == *'"status":"ok"'* ]]
