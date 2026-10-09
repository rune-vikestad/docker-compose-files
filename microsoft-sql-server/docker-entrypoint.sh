#!/bin/bash
set -euo pipefail

INITDB_FOLDER="/docker-entrypoint-initdb.d"
INITDB_LOG_FILE="/var/log/docker/mssql-initdb.log"
# Lives in the data volume, so init scripts run once per volume, like the postgres image does
INITDB_MARKER_FILE="/var/opt/mssql/.docker-initdb-complete"

log() { echo "[$(date +'%H:%M:%S')] $*"; }

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
sql_pid=$!

# Bash as PID 1 does not forward signals, so pass SIGTERM on to let SQL Server shut down cleanly
stop_sql_server() { kill -TERM "$sql_pid" 2>/dev/null || true; }
trap stop_sql_server TERM INT

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

# Apply init scripts once (explicit logging when none found). The marker is only
# written after every script succeeds, so a failed init is retried on next start.
if [[ -f "$INITDB_MARKER_FILE" ]]; then
  log "Init scripts already applied, skipping (remove the data volume to re-run them)"
else
  shopt -s nullglob
  found=0
  for f in "$INITDB_FOLDER"/*.sql; do
    [[ -e "$f" ]] || continue
    found=1
    log "Applying $(basename "$f")"
    # -b makes sqlcmd exit non-zero on SQL errors, which it otherwise reports and ignores
    if ! /opt/mssql-tools18/bin/sqlcmd -C -b -S 127.0.0.1,1433 -U sa -P "${MSSQL_SA_PASSWORD}" \
         -d master -i "$f" | tee -a "$INITDB_LOG_FILE"; then
      log "Failed to apply $(basename "$f")"
      stop_sql_server
      wait "$sql_pid" || true
      exit 1
    fi
  done
  (( found == 1 )) || log "No .sql files found in ${INITDB_FOLDER}"
  touch "$INITDB_MARKER_FILE"
fi

# Keep SQL Server in the foreground. A trapped signal interrupts wait early,
# so keep waiting until sqlservr has actually exited, then pass on its status.
status=0
while kill -0 "$sql_pid" 2>/dev/null; do
  wait "$sql_pid" || status=$?
done
exit "$status"
