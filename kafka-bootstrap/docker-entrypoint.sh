#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS:-kafka:9092}"
DEFAULT_PARTITIONS="${DEFAULT_PARTITIONS:-1}"
DEFAULT_REPLICATION_FACTOR="${DEFAULT_REPLICATION_FACTOR:-1}"
WAIT_MAX_TRIES="${WAIT_MAX_TRIES:-60}"

# Fixed in-image topics directory (not configurable)
TOPIC_DIR="/usr/local/share/kafka-bootstrap"

# Prints a timestamped info line
log() { echo "[$(date +'%H:%M:%S')] $*"; }

# Prints an error and exits non-zero
fail() { echo "ERROR: $*" >&2; exit 1; }

# Asserts that a given command is available
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"; }

# Polls Kafka until reachable or times out
wait_for_kafka() {
  local tries=0
  while (( tries < WAIT_MAX_TRIES )); do
    if kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVERS" --list >/dev/null 2>&1; then
      log "Kafka is reachable at ${BOOTSTRAP_SERVERS}"
      return 0
    fi
    tries=$((tries+1))
    log "Waiting for Kafka (${tries}/${WAIT_MAX_TRIES})..."
    sleep 1
  done
  fail "Kafka not reachable at ${BOOTSTRAP_SERVERS}"
}

# Returns 0 if topic exists, 1 otherwise
topic_exists() {
  local t="$1"
  kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVERS" --describe --topic "$t" >/dev/null 2>&1
}

# Creates a topic with partitions, replication, and optional configs
create_topic() {
  local name="$1" parts="$2" repl="$3" configs_csv="${4:-}"

  if topic_exists "$name"; then
    log "Skipped (already exists) topic '${name}'"
    return 0
  fi

  local args=(--bootstrap-server "$BOOTSTRAP_SERVERS" --create --topic "$name" --partitions "$parts" --replication-factor "$repl")

  if [[ -n "$configs_csv" ]]; then
    IFS=',' read -r -a kvs <<< "$configs_csv"
    for kv in "${kvs[@]}"; do
      [[ -n "$kv" ]] || continue
      args+=(--config "$kv")
    done
  fi

  local stderr_file; stderr_file="$(mktemp)"
  if kafka-topics.sh "${args[@]}" 2>"$stderr_file"; then
    log "Created topic '${name}' (partitions=${parts}, rf=${repl}${configs_csv:+, configs=${configs_csv}})"
  else
    log "kafka-topics.sh error for '${name}':"
    cat "$stderr_file" >&2
    rm -f "$stderr_file"
    fail "Failed to create topic '${name}'"
  fi
  rm -f "$stderr_file"
}

# Flattens a JSON object to k=v,k=v list
flatten_config_obj() {
  jq -r '
    . // {} | to_entries |
    map("\(.key)=\(.value|tostring)") | join(",")
  '
}

# Discovers *.json topic files and creates one topic per file
bootstrap_from_dir() {
  if [[ ! -d "$TOPIC_DIR" ]]; then
    log "Topic directory not found: ${TOPIC_DIR} (nothing to do)"
    return 0
  fi

  shopt -s nullglob
  local found=0
  for f in "$TOPIC_DIR"/*.json; do
    found=1
    local name parts repl configs_csv
    name="$(jq -r '.name // empty' < "$f" || true)"
    [[ -n "$name" ]] || { log "Skipping $(basename "$f") (missing 'name')"; continue; }

    parts="$(jq -r '.partitions // empty' < "$f" || true)"; parts="${parts:-$DEFAULT_PARTITIONS}"
    repl="$(jq -r '.replication_factor // empty' < "$f" || true)"; repl="${repl:-$DEFAULT_REPLICATION_FACTOR}"
    configs_csv="$(jq -c '.config // {}' < "$f" | flatten_config_obj || true)"
    [[ "$configs_csv" == "null" ]] && configs_csv=""

    log "Topic spec -> ${name} (partitions=${parts}, rf=${repl}${configs_csv:+, configs=${configs_csv}}) from $(basename "$f")"
    create_topic "$name" "$parts" "$repl" "$configs_csv"
  done
  (( found == 1 )) || log "No topic json files found in ${TOPIC_DIR}"
}

# Validates dependencies, waits for Kafka, creates topics from dir, optionally execs CMD
main() {
  need_cmd kafka-topics.sh
  need_cmd jq

  log "Bootstrap servers: ${BOOTSTRAP_SERVERS}"
  log "Topic directory: ${TOPIC_DIR}"
  log "Defaults: partitions=${DEFAULT_PARTITIONS}, rf=${DEFAULT_REPLICATION_FACTOR}"

  wait_for_kafka
  bootstrap_from_dir

  log "Kafka topics bootstrap complete."

  if (( $# )); then
    exec "$@"
  fi
}

main "$@"
