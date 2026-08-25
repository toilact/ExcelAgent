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
chmod +x "$test_dir/bin/openssl"

expected_challenge=$(printf "%064d" 2)
PATH="$test_dir/bin:$PATH" "$repo_root/scripts/dev" --no-open >/dev/null 2>&1 &
launcher_pid=$!

actual_challenge=""
for _ in {1..80}; do
  actual_challenge=$(curl -fsS --connect-timeout 1 --max-time 1 \
    http://127.0.0.1:5173/__excelagent/ready 2>/dev/null || true)
  if [[ $actual_challenge == "$expected_challenge" ]] && \
    kill -0 "$launcher_pid" 2>/dev/null; then
    break
  fi
  kill -0 "$launcher_pid" 2>/dev/null || break
  sleep 0.1
done

if [[ $actual_challenge != "$expected_challenge" ]]; then
  echo "Vite did not return the current launcher instance challenge" >&2
  exit 1
fi
if ! kill -0 "$launcher_pid" 2>/dev/null; then
  echo "Launcher stopped after the instance challenge became ready" >&2
  exit 1
fi
