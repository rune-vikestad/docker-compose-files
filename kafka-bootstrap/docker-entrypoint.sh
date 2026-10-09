#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS:-kafka:9092}"
SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://apicurio-registry:8080/apis/ccompat/v7}"
DEFAULT_PARTITIONS="${DEFAULT_PARTITIONS:-1}"
DEFAULT_REPLICATION_FACTOR="${DEFAULT_REPLICATION_FACTOR:-1}"
WAIT_MAX_TRIES="${WAIT_MAX_TRIES:-60}"

# Fixed in-image directories (not configurable)
TOPIC_DIR="/usr/local/share/kafka-bootstrap/topics"
SCHEMA_DIR="/usr/local/share/kafka-bootstrap/schemas"

# Types that carry a schema, and so register a subject, against types that do not.
# JSON or XML without a schema is STRING: the same bytes, the same serializer, and nothing to register.
SCHEMA_TYPES="AVRO JSON PROTOBUF"
RAW_TYPES="STRING BINARY"

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

# Polls the schema registry until reachable or times out
wait_for_registry() {
  local tries=0
  while (( tries < WAIT_MAX_TRIES )); do
    if curl -fsS "${SCHEMA_REGISTRY_URL}/subjects" >/dev/null 2>&1; then
      log "Schema registry is reachable at ${SCHEMA_REGISTRY_URL}"
      return 0
    fi
    tries=$((tries+1))
    log "Waiting for schema registry (${tries}/${WAIT_MAX_TRIES})..."
    sleep 1
  done
  fail "Schema registry not reachable at ${SCHEMA_REGISTRY_URL}, and a topic declares a schema that has to be registered there"
}

# Echoes a field of .key or .value for a topic file, or empty
side_field() {
  local file="$1" side="$2" field="$3"
  jq -r --arg s "$side" --arg f "$field" '(.[$s] // {})[$f] // empty' < "$file"
}

# Echoes the declared type of .key or .value, defaulting to STRING
side_type() {
  local file="$1" side="$2"
  local type; type="$(side_field "$file" "$side" "type")"
  echo "${type:-STRING}"
}

# Returns 0 if the given type registers a subject
type_carries_schema() {
  case " ${SCHEMA_TYPES} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Fails unless .key/.value is a supported type, and its schema is present exactly when the type needs one
validate_side() {
  local file="$1" side="$2"
  local base; base="$(basename "$file")"
  local type schema
  type="$(side_type "$file" "$side")"
  schema="$(side_field "$file" "$side" "schema")"

  case " ${SCHEMA_TYPES} ${RAW_TYPES} " in
    *" $type "*) ;;
    *) fail "${base}: ${side}.type '${type}' is not one of ${SCHEMA_TYPES} ${RAW_TYPES}" ;;
  esac

  if type_carries_schema "$type"; then
    # Silently skipping registration is how a producer fails much later, with an error naming nothing useful.
    [[ -n "$schema" ]] \
      || fail "${base}: ${side}.type is ${type}, which needs a 'schema'"
    [[ -f "${SCHEMA_DIR}/${schema}" ]] \
      || fail "${base}: ${side}.schema '${schema}' was not found in ${SCHEMA_DIR}"
  else
    [[ -z "$schema" ]] \
      || fail "${base}: ${side}.type is ${type}, which registers nothing, so 'schema' cannot be honoured"
  fi
}

# Registers one schema under <topic>-<side>, which is how SubjectNameStrategy.Topic names it
register_subject() {
  local topic="$1" side="$2" type="$3" schema="$4"
  local subject="${topic}-${side}"

  local body; body="$(jq -n --arg t "$type" --rawfile s "${SCHEMA_DIR}/${schema}" '{schemaType: $t, schema: $s}')"

  local tmp; tmp="$(mktemp)"
  local code
  code=$(curl -sS -o "$tmp" -w "%{http_code}" -X POST \
           -H "Content-Type: application/vnd.schemaregistry.v1+json" \
           --data-binary @- "${SCHEMA_REGISTRY_URL}/subjects/${subject}/versions" <<< "$body")

  if [[ "$code" == "200" ]]; then
    log "Registered ${type} subject '${subject}' (id=$(jq -r '.id // "?"' < "$tmp")) from ${schema}"
    rm -f "$tmp"
  else
    log "POST failed (HTTP ${code}) for subject '${subject}'"
    head -c 2048 "$tmp" | sed -e 's/\r$//'
    echo
    rm -f "$tmp"
    fail "Failed to register subject '${subject}' (HTTP ${code})"
  fi
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

    local key_type value_type
    key_type="$(side_type "$f" "key")"
    value_type="$(side_type "$f" "value")"

    log "Topic spec -> ${name} (partitions=${parts}, rf=${repl}, key=${key_type}, value=${value_type}${configs_csv:+, configs=${configs_csv}}) from $(basename "$f")"
    create_topic "$name" "$parts" "$repl" "$configs_csv"
  done
  (( found == 1 )) || log "No topic json files found in ${TOPIC_DIR}"
}

# Fails on any malformed topic file before anything is created, so a typo cannot half-apply
validate_all() {
  [[ -d "$TOPIC_DIR" ]] || return 0

  shopt -s nullglob
  for f in "$TOPIC_DIR"/*.json; do
    jq -e . < "$f" >/dev/null 2>&1 || fail "$(basename "$f") is not valid JSON"
    [[ -n "$(jq -r '.name // empty' < "$f")" ]] || continue

    validate_side "$f" "key"
    validate_side "$f" "value"
  done
}

# Returns 0 if any topic declares a schema, so the registry is only required when there is something to register
any_schema_declared() {
  [[ -d "$TOPIC_DIR" ]] || return 1

  shopt -s nullglob
  for f in "$TOPIC_DIR"/*.json; do
    for side in key value; do
      type_carries_schema "$(side_type "$f" "$side")" && return 0
    done
  done
  return 1
}

# Registers every declared key and value schema under the topic it belongs to
register_subjects_from_dir() {
  shopt -s nullglob
  for f in "$TOPIC_DIR"/*.json; do
    local name; name="$(jq -r '.name // empty' < "$f")"
    [[ -n "$name" ]] || continue

    for side in key value; do
      local type; type="$(side_type "$f" "$side")"
      type_carries_schema "$type" || continue
      register_subject "$name" "$side" "$type" "$(side_field "$f" "$side" "schema")"
    done
  done
}

# Validates dependencies, waits for Kafka, creates topics from dir, optionally execs CMD
main() {
  need_cmd kafka-topics.sh
  need_cmd jq
  need_cmd curl

  log "Bootstrap servers: ${BOOTSTRAP_SERVERS}"
  log "Topic directory: ${TOPIC_DIR}"
  log "Schema directory: ${SCHEMA_DIR}"
  log "Defaults: partitions=${DEFAULT_PARTITIONS}, rf=${DEFAULT_REPLICATION_FACTOR}"

  validate_all

  wait_for_kafka
  bootstrap_from_dir

  if any_schema_declared; then
    log "Schema registry: ${SCHEMA_REGISTRY_URL}"
    wait_for_registry
    register_subjects_from_dir
  else
    log "No topic declares a schema, so nothing is registered."
  fi

  log "Kafka topics bootstrap complete."

  if (( $# )); then
    exec "$@"
  fi
}

main "$@"
