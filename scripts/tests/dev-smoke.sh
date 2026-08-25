#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
launcher_pid=""
cleanup() {
  [[ -n $launcher_pid ]] && kill "$launcher_pid" 2>/dev/null || true
  [[ -n $launcher_pid ]] && wait "$launcher_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

"$repo_root/scripts/dev" --no-open &
launcher_pid=$!
health=""
ui_ready=0
for _ in {1..120}; do
  health=$(curl -fsS http://127.0.0.1:8000/api/health 2>/dev/null || true)
  if [[ $health == *'"service":"excel-agent-api"'* ]] && \
    curl -fsS http://127.0.0.1:5173/ >/dev/null 2>&1; then
    ui_ready=1
    break
  fi
  kill -0 "$launcher_pid" 2>/dev/null || break
  sleep 0.25
done

[[ $ui_ready -eq 1 ]] || { echo "Development smoke test timed out" >&2; exit 1; }
[[ $health == *'"status":"ok"'* ]]
