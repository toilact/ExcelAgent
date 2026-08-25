#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
server_pid=""
cleanup() {
  [[ -n $server_pid ]] && kill "$server_pid" 2>/dev/null || true
  [[ -n $server_pid ]] && wait "$server_pid" 2>/dev/null || true
  [[ -d $test_dir ]] && rm -rf "$test_dir"
}
trap cleanup EXIT INT TERM

generation_marker="$test_dir/token-generated"
open_marker="$test_dir/browser-opened"
mkdir "$test_dir/bin"
printf '#!/usr/bin/env bash\ntouch "%s"\nprintf "%%s\\n" "deterministic-test-token"\n' \
  "$generation_marker" >"$test_dir/bin/openssl"
printf '#!/usr/bin/env bash\ntouch "%s"\n' \
  "$open_marker" >"$test_dir/bin/open"
chmod +x "$test_dir/bin/openssl" "$test_dir/bin/open"
PATH="$test_dir/bin:$PATH" openssl rand -hex 32 >/dev/null
if [[ ! -e $generation_marker ]]; then
  echo "Test openssl stub did not run" >&2
  exit 1
fi
unlink "$generation_marker"

assert_occupied_port_fails_closed() {
  local port=$1
  local launcher_output
  local launcher_status

  uv --directory "$repo_root/backend" run python -m http.server "$port" \
    --bind 127.0.0.1 >/dev/null 2>&1 &
  server_pid=$!
  for _ in {1..40}; do
    curl -fsS --connect-timeout 1 --max-time 1 \
      "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
    sleep 0.1
  done
  curl -fsS --connect-timeout 1 --max-time 1 \
    "http://127.0.0.1:$port/" >/dev/null

  set +e
  launcher_output=$(PATH="$test_dir/bin:$PATH" /bin/bash "$repo_root/scripts/dev" 2>&1)
  launcher_status=$?
  set -e

  if [[ $launcher_status -eq 0 ]]; then
    echo "Launcher succeeded while port $port was occupied" >&2
    return 1
  fi
  if [[ -e $generation_marker ]]; then
    echo "Launcher generated a token while port $port was occupied" >&2
    return 1
  fi
  if [[ -e $open_marker ]]; then
    echo "Launcher opened a token URL while port $port was occupied" >&2
    return 1
  fi
  if [[ $launcher_output == *"#token="* ]]; then
    echo "Launcher printed a token fragment while port $port was occupied" >&2
    return 1
  fi

  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
  server_pid=""
}

assert_occupied_port_fails_closed 8000
assert_occupied_port_fails_closed 5173
