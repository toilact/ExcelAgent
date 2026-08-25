#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
launcher_pid=""
cleanup() {
  [[ -n $launcher_pid ]] && kill "$launcher_pid" 2>/dev/null || true
  [[ -n $launcher_pid ]] && wait "$launcher_pid" 2>/dev/null || true
  [[ -d $test_dir ]] && rm -rf "$test_dir"
}
trap cleanup EXIT INT TERM

assert_port_free() {
  uv --directory "$repo_root/backend" run python -c '
import socket
import sys

with socket.socket() as listener:
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", int(sys.argv[1])))
' "$1"
}

# The race starts only after the launcher has completed its port preflight:
# replacing npm causes a stale-looking UI to bind where Vite was expected.
assert_port_free 8000
assert_port_free 5173

mkdir "$test_dir/bin"
openssl_count="$test_dir/openssl-count"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'count=0' \
  '[[ -f "'"$openssl_count"'" ]] && read -r count <"'"$openssl_count"'"' \
  'count=$((count + 1))' \
  'printf "%s\n" "$count" >"'"$openssl_count"'"' \
  'if [[ $count -eq 1 ]]; then' \
  '  printf "%064d\n" 1' \
  'else' \
  '  printf "%064d\n" 2' \
  'fi' >"$test_dir/bin/openssl"

open_marker="$test_dir/browser-opened"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'touch "'"$open_marker"'"' \
  'exit 73' >"$test_dir/bin/open"

printf '%s\n' \
  'import http.server' \
  'import os' \
  'import threading' \
  '' \
  'class Handler(http.server.BaseHTTPRequestHandler):' \
  '    def do_GET(self):' \
  '        body = b"<!doctype html><html><body>ExcelAgent</body></html>"' \
  '        self.send_response(200)' \
  '        self.send_header("Content-Type", "text/html")' \
  '        self.send_header("Content-Length", str(len(body)))' \
  '        self.end_headers()' \
  '        self.wfile.write(body)' \
  '' \
  '    def log_message(self, *_args):' \
  '        pass' \
  '' \
  'threading.Timer(5.0, lambda: os._exit(0)).start()' \
  'http.server.ThreadingHTTPServer(("127.0.0.1", 5173), Handler).serve_forever()' \
  >"$test_dir/stale_ui.py"

backend_python=$(uv --directory "$repo_root/backend" run python -c 'import sys; print(sys.executable)')
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'exec "'"$backend_python"'" "'"$test_dir/stale_ui.py"'"' \
  >"$test_dir/bin/npm"
chmod +x "$test_dir/bin/openssl" "$test_dir/bin/open" "$test_dir/bin/npm"

set +e
launcher_output=$(PATH="$test_dir/bin:$PATH" /bin/bash "$repo_root/scripts/dev" 2>&1)
launcher_status=$?
set -e

if [[ $launcher_status -eq 0 ]]; then
  echo "Launcher succeeded after a stale UI won the startup race" >&2
  exit 1
fi
if [[ -e $open_marker ]]; then
  echo "Launcher opened the browser for a stale UI instance" >&2
  exit 1
fi
if [[ $launcher_output == *"#token="* ]]; then
  echo "Launcher emitted a token fragment during the UI race" >&2
  exit 1
fi

assert_port_free 8000
assert_port_free 5173
