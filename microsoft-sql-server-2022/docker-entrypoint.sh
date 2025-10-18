#!/bin/bash
set -euo pipefail

INITDB_FOLDER="/docker-entrypoint-initdb.d"
INITDB_LOG_FILE="/var/log/docker/mssql-initdb.log"

log() { echo "[$(date +'%H:%M:%S')] $*"; }

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
sql_pid=$!

# Wait for readiness
tries=0
max_tries=60
while (( tries < max_tries )); do
  if /opt/mssql-tools18/bin/sqlcmd -C -l 2 -S 127.0.0.1,1433 \
       -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SELECT 1" >/dev/null 2>&1; then
    log "SQL Server is ready"
    break
  fi
  tries=$((tries+1))
  log "Waiting for SQL Server (${tries}/${max_tries})..."
  sleep 1
done
if (( tries >= max_tries )); then
  log "SQL Server did not become ready in time"
  kill "$sql_pid" || true
  wait "$sql_pid" || true
  exit 1
fi

# Apply init scripts (explicit logging when none found)
shopt -s nullglob
found=0
for f in "$INITDB_FOLDER"/*.sql; do
  [[ -e "$f" ]] || continue
  found=1
  log "Applying $(basename "$f")"
  /opt/mssql-tools18/bin/sqlcmd -C -S 127.0.0.1,1433 -U sa -P "${MSSQL_SA_PASSWORD}" \
    -d master -i "$f" | tee -a "$INITDB_LOG_FILE"
done
(( found == 1 )) || log "No .sql files found in ${INITDB_FOLDER}"

# Keep SQL Server in the foreground
wait "$sql_pid"
