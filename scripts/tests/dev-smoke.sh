#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
launcher_pid=""
cleanup() {
  [[ -n $launcher_pid ]] && kill "$launcher_pid" 2>/dev/null || true
  [[ -n $launcher_pid ]] && wait "$launcher_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

readiness_deadline=$((SECONDS + 29))
set_curl_budget() {
  curl_request_timeout=$((readiness_deadline - SECONDS))
  [[ $curl_request_timeout -gt 0 ]] || return 1
  [[ $curl_request_timeout -le 1 ]] || curl_request_timeout=1
}

# Share one deadline across pre-launch checks, both readiness probes, and
# sleeps. The reserve covers Bash 3.2's whole-second clock granularity.
set_curl_budget || { echo "Development smoke test timed out" >&2; exit 1; }
api_already_ready=0
if curl -fsS --connect-timeout "$curl_request_timeout" \
  --max-time "$curl_request_timeout" \
  http://127.0.0.1:8000/api/health >/dev/null 2>&1; then
  api_already_ready=1
fi
set_curl_budget || { echo "Development smoke test timed out" >&2; exit 1; }
ui_already_ready=0
if curl -fsS --connect-timeout "$curl_request_timeout" \
  --max-time "$curl_request_timeout" \
  http://127.0.0.1:5173/ >/dev/null 2>&1; then
  ui_already_ready=1
fi
if [[ $api_already_ready -eq 1 || $ui_already_ready -eq 1 ]]; then
  echo "Development smoke test requires free ports 8000 and 5173" >&2
  exit 1
fi

"$repo_root/scripts/dev" --no-open &
launcher_pid=$!
health=""
ui_ready=0
while set_curl_budget; do
  health=$(curl -fsS --connect-timeout "$curl_request_timeout" \
    --max-time "$curl_request_timeout" \
    http://127.0.0.1:8000/api/health 2>/dev/null || true)
  if [[ $health == *'"service":"excel-agent-api"'* ]]; then
    if set_curl_budget && \
      curl -fsS --connect-timeout "$curl_request_timeout" \
        --max-time "$curl_request_timeout" \
        http://127.0.0.1:5173/ >/dev/null 2>&1; then
      if kill -0 "$launcher_pid" 2>/dev/null; then
        ui_ready=1
        break
      fi
      break
    fi
  fi
  kill -0 "$launcher_pid" 2>/dev/null || break
  set_curl_budget || break
  sleep 0.25
done

[[ $ui_ready -eq 1 ]] || { echo "Development smoke test timed out" >&2; exit 1; }
[[ $health == *'"status":"ok"'* ]]
