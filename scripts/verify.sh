#!/usr/bin/env bash
set -u

DB_HOST="${DB_HOST:-}"
DB_NAME="${DB_NAME:-lampdb}"
DB_USER="${DB_USER:-lampuser}"
DB_PASSWORD="${DB_PASSWORD:-}"
APP_PORT="${APP_PORT:-5000}"

if [[ $# -ge 1 ]]; then
  DB_HOST="$1"
fi

pass_count=0
fail_count=0

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

pass() {
  echo "[PASS] $1"
  pass_count=$((pass_count + 1))
}

fail() {
  echo "[FAIL] $1"
  fail_count=$((fail_count + 1))
}

run_check() {
  local label="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

print_header "Section 07 Quick Verification (Web Server)"

echo "Host: $(hostname)"
echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

print_header "System Services"
run_check "Docker service active" sudo systemctl is-active --quiet docker
run_check "NGINX service active" sudo systemctl is-active --quiet nginx

print_header "Docker Container"
run_check "lamp-app container is running" sudo docker ps --format '{{.Names}}' | grep -qx lamp-app
run_check "App health on localhost:${APP_PORT}" curl -fsS "http://localhost:${APP_PORT}/health"
run_check "App health via NGINX localhost:80" curl -fsS "http://localhost/health"

print_header "Web Server Ports"
run_check "Port 80 listening" sudo ss -tulpn | grep -q ':80 '
run_check "Port ${APP_PORT} listening" sudo ss -tulpn | grep -q ":${APP_PORT} "

print_header "Database Connectivity"
if [[ -z "$DB_HOST" ]]; then
  echo "DB_HOST not provided. Skipping DB checks."
  echo "Tip: DB_HOST=<db-private-ip> DB_PASSWORD=<password> ./scripts/verify.sh"
else
  run_check "DB port reachable (${DB_HOST}:3306)" bash -lc "timeout 5 bash -c '</dev/tcp/${DB_HOST}/3306'"

  if ! command -v mysql >/dev/null 2>&1; then
    fail "mysql client installed"
  else
    pass "mysql client installed"

    if [[ -z "$DB_PASSWORD" ]]; then
      echo "DB_PASSWORD not provided. Skipping authenticated MySQL query."
      echo "Tip: DB_HOST=${DB_HOST} DB_PASSWORD=... ./scripts/verify.sh"
    else
      run_check "Authenticated MySQL query" bash -lc "MYSQL_PWD='${DB_PASSWORD}' mysql -h '${DB_HOST}' -u '${DB_USER}' -D '${DB_NAME}' -e 'SELECT 1;'"
      run_check "visitors table exists" bash -lc "MYSQL_PWD='${DB_PASSWORD}' mysql -h '${DB_HOST}' -u '${DB_USER}' -D '${DB_NAME}' -e 'SHOW TABLES LIKE \"visitors\";' | grep -q visitors"
    fi
  fi
fi

print_header "Summary"
echo "Passed: ${pass_count}"
echo "Failed: ${fail_count}"

if [[ $fail_count -gt 0 ]]; then
  echo "Result: FAIL"
  exit 1
fi

echo "Result: PASS"
exit 0
