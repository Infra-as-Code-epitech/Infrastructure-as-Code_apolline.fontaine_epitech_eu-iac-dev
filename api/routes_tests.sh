#!/usr/bin/env bash
set -euo pipefail

# Simple integration tests for the FastAPI /tasks routes.
# Requirements: python, curl, uvicorn (or run the app separately and set BASE)
# Usage: bash test_routes.sh

# BASE must be set to LoadBalancer endpoint
BASE="http://127.0.0.1:8000"
APP_MODULE="app.main:app"
LOGFILE="./uvicorn.test.log"
START_SERVER=true

# detect helpers
command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python is required"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  JQ_CMD=""
else
  JQ_CMD="jq"
fi

json_extract() {
  # usage: json_extract <file> <jq_filter>
  local file="$1"; shift
  if [ -n "$JQ_CMD" ]; then
    jq -r "$@" "$file"
  else
    python - <<PY - "$file" "$@"
import sys, json
f = sys.argv[1]
flt = sys.argv[2] if len(sys.argv) > 2 else "."
with open(f) as fh:
    obj = json.load(fh)
# very small "jq-like" extraction for common patterns: top-level key
k = flt.lstrip('.')
val = obj.get(k)
print(val if val is not None else "")
PY
  fi
}

cleanup() {
  if [ -n "${UVICORN_PID-}" ]; then
    kill "$UVICORN_PID" 2>/dev/null || true
    wait "$UVICORN_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Start server if uvicorn is available
if command -v uvicorn >/dev/null 2>&1 && [ "$START_SERVER" = true ]; then
  echo "Starting uvicorn ($APP_MODULE) on $BASE ..."
  uvicorn "$APP_MODULE" --host 127.0.0.1 --port 8001 >"$LOGFILE" 2>&1 &
  UVICORN_PID=$!
  # wait for openapi to respond
  for i in $(seq 1 20); do
    status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/openapi.json" || echo "000")
    if [ "$status" = "200" ]; then
      break
    fi
    sleep 0.3
  done
  echo "server log: $LOGFILE"
fi

echo "1) Create todo (POST /tasks)"
create_resp="$(mktemp)"
status=$(curl -sS -o "$create_resp" -w "%{http_code}" -X POST "$BASE/tasks" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Todo","description":"created by test"}' || echo "000")
if [ "$status" != "201" ]; then
  echo "FAILED: expected 201, got $status"
  cat "$create_resp" || true
  exit 2
fi
todo_id=$(json_extract "$create_resp" '.id')
echo " -> created id=$todo_id"

echo "2) List tasks (GET /tasks)"
list_resp="$(mktemp)"
status=$(curl -sS -o "$list_resp" -w "%{http_code}" "$BASE/tasks" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from list, got $status"; cat "$list_resp"; exit 3
fi

if  grep -q "\"id\": $todo_id" "$list_resp"; then
  echo "FAILED: created todo id not found in list:"
  cat "$list_resp"
  exit 4
fi
echo " -> present in list"

echo "3) Get single todo (GET /tasks/{id})"
get_resp="$(mktemp)"
status=$(curl -sS -o "$get_resp" -w "%{http_code}" "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from get, got $status"; cat "$get_resp"; exit 5
fi
title=$(json_extract "$get_resp" '.title')
if [ "$title" != "Test Todo" ]; then
  echo "FAILED: title mismatch: $title"; cat "$get_resp"; exit 6
fi
echo " -> title OK"

echo "4) Update todo (PUT /tasks/{id})"
put_resp="$(mktemp)"
status=$(curl -sS -o "$put_resp" -w "%{http_code}" -X PUT "$BASE/tasks/$todo_id" \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title","description":"updated"}' || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from put, got $status"; cat "$put_resp"; exit 7
fi
newtitle=$(json_extract "$put_resp" '.title')
if [ "$newtitle" != "Updated Title" ]; then
  echo "FAILED: put did not update title: $newtitle"; exit 8
fi
echo " -> update OK"

echo "5) Toggle complete (PATCH /tasks/{id}/complete)"
patch_resp="$(mktemp)"
status=$(curl -sS -o "$patch_resp" -w "%{http_code}" -X PATCH "$BASE/tasks/$todo_id/complete" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from patch, got $status"; cat "$patch_resp"; exit 9
fi
completed=$(json_extract "$patch_resp" '.completed')
if [ "$completed" != "true" ]; then
  echo "FAILED: expected completed=true, got $completed"; exit 10
fi
echo " -> completed toggled"

echo "6) Delete todo (DELETE /tasks/{id})"
status=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "204" ]; then
  echo "FAILED: expected 204 from delete, got $status"; exit 11
fi
echo " -> deleted"

echo "7) Verify deletion (GET /tasks/{id}) expects 404"
status=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "404" ]; then
  echo "FAILED: expected 404 after delete, got $status"; exit 12
fi

echo "All tests passed."
exit 0
```# filepath: /home/deadpanda/tek/infraascode/api/test_routes.sh
#!/usr/bin/env bash
set -euo pipefail

# Simple integration tests for the FastAPI /tasks routes.
# Requirements: python, curl, uvicorn (or run the app separately and set BASE)
# Usage: bash test_routes.sh

BASE="http://127.0.0.1:8001"
APP_MODULE="app.main:app"
LOGFILE="./uvicorn.test.log"
START_SERVER=true

# detect helpers
command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }
command -v python >/dev/null 2>&1 || { echo "python is required"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  JQ_CMD=""
else
  JQ_CMD="jq"
fi

json_extract() {
  # usage: json_extract <file> <jq_filter>
  local file="$1"; shift
  if [ -n "$JQ_CMD" ]; then
    jq -r "$@" "$file"
  else
    python - <<PY - "$file" "$@"
import sys, json
f = sys.argv[1]
flt = sys.argv[2] if len(sys.argv) > 2 else "."
with open(f) as fh:
    obj = json.load(fh)
# very small "jq-like" extraction for common patterns: top-level key
k = flt.lstrip('.')
val = obj.get(k)
print(val if val is not None else "")
PY
  fi
}

cleanup() {
  if [ -n "${UVICORN_PID-}" ]; then
    kill "$UVICORN_PID" 2>/dev/null || true
    wait "$UVICORN_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Start server if uvicorn is available
if command -v uvicorn >/dev/null 2>&1 && [ "$START_SERVER" = true ]; then
  echo "Starting uvicorn ($APP_MODULE) on $BASE ..."
  uvicorn "$APP_MODULE" --host 127.0.0.1 --port 8001 >"$LOGFILE" 2>&1 &
  UVICORN_PID=$!
  # wait for openapi to respond
  for i in $(seq 1 20); do
    status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/openapi.json" || echo "000")
    if [ "$status" = "200" ]; then
      break
    fi
    sleep 0.3
  done
  echo "server log: $LOGFILE"
fi

echo "1) Create todo (POST /tasks)"
create_resp="$(mktemp)"
status=$(curl -sS -o "$create_resp" -w "%{http_code}" -X POST "$BASE/tasks" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Todo","description":"created by test"}' || echo "000")
if [ "$status" != "201" ]; then
  echo "FAILED: expected 201, got $status"
  cat "$create_resp" || true
  exit 2
fi
todo_id=$(json_extract "$create_resp" '.id')
echo " -> created id=$todo_id"

echo "2) List tasks (GET /tasks)"
list_resp="$(mktemp)"
status=$(curl -sS -o "$list_resp" -w "%{http_code}" "$BASE/tasks" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from list, got $status"; cat "$list_resp"; exit 3
fi
# quick membership check (string match)
if ! grep -q "\"id\": $todo_id" "$list_resp"; then
  echo "FAILED: created todo id not found in list"
  cat "$list_resp"
  exit 4
fi
echo " -> present in list"

echo "3) Get single todo (GET /tasks/{id})"
get_resp="$(mktemp)"
status=$(curl -sS -o "$get_resp" -w "%{http_code}" "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from get, got $status"; cat "$get_resp"; exit 5
fi
title=$(json_extract "$get_resp" '.title')
if [ "$title" != "Test Todo" ]; then
  echo "FAILED: title mismatch: $title"; cat "$get_resp"; exit 6
fi
echo " -> title OK"

echo "4) Update todo (PUT /tasks/{id})"
put_resp="$(mktemp)"
status=$(curl -sS -o "$put_resp" -w "%{http_code}" -X PUT "$BASE/tasks/$todo_id" \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title","description":"updated"}' || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from put, got $status"; cat "$put_resp"; exit 7
fi
newtitle=$(json_extract "$put_resp" '.title')
if [ "$newtitle" != "Updated Title" ]; then
  echo "FAILED: put did not update title: $newtitle"; exit 8
fi
echo " -> update OK"

echo "5) Toggle complete (PATCH /tasks/{id}/complete)"
patch_resp="$(mktemp)"
status=$(curl -sS -o "$patch_resp" -w "%{http_code}" -X PATCH "$BASE/tasks/$todo_id/complete" || echo "000")
if [ "$status" != "200" ]; then
  echo "FAILED: expected 200 from patch, got $status"; cat "$patch_resp"; exit 9
fi
completed=$(json_extract "$patch_resp" '.completed')
if [ "$completed" != "true" ]; then
  echo "FAILED: expected completed=true, got $completed"; exit 10
fi
echo " -> completed toggled"

echo "6) Delete todo (DELETE /tasks/{id})"
status=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "204" ]; then
  echo "FAILED: expected 204 from delete, got $status"; exit 11
fi
echo " -> deleted"

echo "7) Verify deletion (GET /tasks/{id}) expects 404"
status=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/tasks/$todo_id" || echo "000")
if [ "$status" != "404" ]; then
  echo "FAILED: expected 404 after delete, got $status"; exit 12
fi

echo "All tests passed."
