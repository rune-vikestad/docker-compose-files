#!/usr/bin/env bash

set -euo pipefail

REGISTRY_URL="${REGISTRY_URL:-http://apicurio-registry:8080/apis/registry/v3}"
REGISTRY_FALLBACK_GROUP="${REGISTRY_FALLBACK_GROUP:-default}"
SCHEMA_DIR="${SCHEMA_DIR:-/usr/local/share/apicurio/schemas}"
ARTIFACT_ID_SUFFIX_BY_TYPE="${ARTIFACT_ID_SUFFIX_BY_TYPE:-true}"
RESOLVE_VERSION_FROM_NAMESPACE="${RESOLVE_VERSION_FROM_NAMESPACE:-true}"
LOG_FAILED_HTTP_RESPONSE_HEADERS="${LOG_FAILED_HTTP_RESPONSE_HEADERS:-true}"
LOG_FAILED_HTTP_RESPONSE_BODY="${LOG_FAILED_HTTP_RESPONSE_BODY:-true}"

# Prints a timestamped info line
log()  { echo "[$(date +'%H:%M:%S')] $*"; }

# Prints an error and exits non-zero
fail() { echo "ERROR: $*" >&2; exit 1; }

# Asserts that a given command is available
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"; }

# URL-encodes a string using jq @uri (compatible flags for older jq)
urlenc() { jq -n -r --arg s "$1" '$s|@uri'; }

# Trims CR/LF & spaces, lowercases, strips trailing .json/.proto from a group id
normalize_group() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  s="${s,,}"
  [[ "$s" == *.json ]] && s="${s%.json}"
  [[ "$s" == *.proto ]] && s="${s%.proto}"
  echo "$s"
}

# If enabled and group has exactly one '.vN' segment, returns 'N.0.0'; otherwise empty
derive_semver_from_group() {
  local g="$1"
  if [[ "${RESOLVE_VERSION_FROM_NAMESPACE,,}" != "true" ]]; then
    echo ""; return
  fi
  IFS='.' read -r -a parts <<< "$g"
  local matches=0 num=""
  for seg in "${parts[@]}"; do
    if [[ "$seg" =~ ^v([0-9]+)$ ]]; then
      matches=$((matches+1))
      num="${BASH_REMATCH[1]}"
    fi
  done
  if (( matches == 1 )); then
    echo "${num}.0.0"
  else
    echo ""
  fi
}

# Polls the registry until reachable or times out
wait_for_registry() {
  local tries=0 max_tries=60
  while (( tries < max_tries )); do
    if curl -fsS "${REGISTRY_URL}/groups?limit=1" >/dev/null 2>&1; then
      log "Registry is reachable at ${REGISTRY_URL}"
      return 0
    fi
    tries=$((tries+1))
    log "Waiting for registry (${tries}/${max_tries})..."
    sleep 1
  done
  fail "Registry not reachable: ${REGISTRY_URL}"
}

# Returns group from Avro .namespace (normalized) or fallback
derive_group_avro() {
  local file="$1"
  local ns
  ns=$(jq -r '.namespace? // empty' < "$file" || true)
  if [[ -n "$ns" ]]; then
    normalize_group "$ns"
    return
  fi
  echo "$REGISTRY_FALLBACK_GROUP"
}

# Returns group from JSON $id (minus final segment; normalized) or fallback
derive_group_json() {
  local file="$1"
  local raw id
  raw=$(jq -r '."$id"? // empty' < "$file" || true)
  if [[ -n "$raw" ]]; then
    id="$raw"
    if [[ "$id" == *"://"* ]]; then
      id="${id##*/}"
      id="${id##*#}"
    fi
    [[ "$id" == *.* ]] && id="${id%.*}"
    if [[ -n "$id" ]]; then
      normalize_group "$id"
      return
    fi
  fi
  echo "$REGISTRY_FALLBACK_GROUP"
}

# Returns group from Protobuf package (normalized) or fallback
derive_group_proto() {
  local file="$1"
  local pkg
  pkg=$(awk '
    /^[[:space:]]*package[[:space:]]+[A-Za-z0-9_.]+[[:space:]]*;/ {
      gsub(/;/,"",$2); print $2; exit
    }' "$file" || true)
  if [[ -n "$pkg" ]]; then
    normalize_group "$pkg"
    return
  fi
  echo "$REGISTRY_FALLBACK_GROUP"
}

# Returns artifactId from Avro .name or filename
derive_artifactId_avro() {
  local file="$1"
  local name
  name=$(jq -r '.name? // empty' < "$file" || true)
  if [[ -n "$name" && "$name" != "null" ]]; then
    echo "$name"; return
  fi
  basename "$file" .avsc
}

# Returns artifactId from JSON $id last segment or filename
derive_artifactId_json() {
  local file="$1"
  local id seg
  id=$(jq -r '."$id"? // empty' < "$file" || true)
  if [[ -n "$id" && "$id" != "null" ]]; then
    if [[ "$id" == *"://"* ]]; then
      id="${id##*/}"
      id="${id##*#}"
    fi
    seg="${id##*.}"
    if [[ -n "$seg" ]]; then
      echo "$seg"; return
    fi
  fi
  basename "$file" .json
}

# Returns artifactId from first top-level message or filename
derive_artifactId_proto() {
  local file="$1"
  local msg
  msg=$(awk '
    /^[[:space:]]*\/\// { next }
    /^[[:space:]]*message[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(\{|$)/ {
      for (i=1;i<=NF;i++) if ($i=="message") { print $(i+1); exit }
    }' "$file" | sed 's/[{;].*$//' )
  if [[ -n "$msg" ]]; then
    echo "$msg"; return
  fi
  basename "$file" .proto
}

# Returns the extension suffix for the artifactId (or empty)
suffix_for_type() {
  local t="$1"
  if [[ "${ARTIFACT_ID_SUFFIX_BY_TYPE}" == "true" ]]; then
    case "$t" in
      AVRO) echo ".avro" ;;
      JSON) echo ".json" ;;
      PROTOBUF) echo ".proto" ;;
      *) echo "" ;;
    esac
  else
    echo ""
  fi
}

# Posts a new artifact (group/type/id/content/version) and logs failures
post_artifact_v3() {
  local group="$1" artifactId="$2" artifactType="$3" content_file="$4" version="${5:-}"

  local contentType="application/json"
  [[ "${artifactType}" == "PROTOBUF" ]] && contentType="text/plain"

  local content
  content="$(cat "$content_file")"
  local content_len; content_len=$(wc -c < "$content_file" | tr -d ' ')

  local body
  if [[ -n "$version" ]]; then
    body=$(jq -n \
      --arg artifactId "${artifactId}" \
      --arg artifactType "${artifactType}" \
      --arg version "${version}" \
      --arg contentType "${contentType}" \
      --arg content "${content}" \
      '{
        artifactId: $artifactId,
        artifactType: $artifactType,
        firstVersion: {
          version: $version,
          content: { content: $content, contentType: $contentType }
        }
      }')
  else
    body=$(jq -n \
      --arg artifactId "${artifactId}" \
      --arg artifactType "${artifactType}" \
      --arg contentType "${contentType}" \
      --arg content "${content}" \
      '{
        artifactId: $artifactId,
        artifactType: $artifactType,
        firstVersion: {
          content: { content: $content, contentType: $contentType }
        }
      }')
  fi

  local group_enc; group_enc="$(urlenc "$group")"

  local tmp_body tmp_hdr
  tmp_body="$(mktemp)"
  tmp_hdr="$(mktemp)"

  local code
  code=$(curl -sS -o "$tmp_body" -D "$tmp_hdr" -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            --data-raw "${body}" \
            "${REGISTRY_URL}/groups/${group_enc}/artifacts")

  if [[ "${code}" == "200" || "${code}" == "201" || "${code}" == "204" ]]; then
    log "Registered ${artifactType} artifact '${artifactId}' in group '${group}'${version:+ (version=${version})}"
    rm -f "$tmp_body" "$tmp_hdr"
  elif [[ "${code}" == "409" ]]; then
    log "Skipped (already exists) ${artifactType} artifact '${artifactId}' in group '${group}'"
    rm -f "$tmp_body" "$tmp_hdr"
  else
    log "POST failed (HTTP ${code}) for '${artifactId}' in group '${group}' (payload=${content_len} bytes${version:+, version=${version}})"
    if [[ "${LOG_FAILED_HTTP_RESPONSE_HEADERS}" == "true" && -s "$tmp_hdr" ]]; then
      log "Response headers:"
      sed -e 's/\r$//' "$tmp_hdr" | head -n 50
    fi
    if [[ "${LOG_FAILED_HTTP_RESPONSE_BODY}" == "true" && -s "$tmp_body" ]]; then
      log "Server response body (first 2KB):"
      head -c 2048 "$tmp_body" | sed -e 's/\r$//'
      echo
    fi
    rm -f "$tmp_body" "$tmp_hdr"
    fail "Failed to register ${artifactType} artifact '${artifactId}' in group '${group}' (HTTP ${code})"
  fi
}

# Yields files matching a glob in SCHEMA_DIR (null-safe, handles spaces)
walk_files() {
  local pattern="$1"
  [[ -d "${SCHEMA_DIR}" ]] || return 0
  find "${SCHEMA_DIR}" -maxdepth 1 -type f -name "${pattern}" -print0
}

# Discovers .avsc files and posts them with derived group/id/version
bootstrap_avro() {
  local any=0
  while IFS= read -r -d '' f; do
    any=1
    local gid; gid="$(derive_group_avro "$f")"
    local ver; ver="$(derive_semver_from_group "$gid")"
    local id;  id="$(derive_artifactId_avro "$f")"
    local sfx; sfx="$(suffix_for_type AVRO)"
    local final_id="${id}${sfx}"
    log "AVRO -> ${final_id} (group='${gid}'${ver:+, version=${ver}}) from $(basename "$f")"
    post_artifact_v3 "${gid}" "${final_id}" "AVRO" "$f" "${ver}"
  done < <(walk_files '*.avsc')
  (( any == 1 )) || log "No .avsc files found in ${SCHEMA_DIR}"
}

# Discovers .json files and posts them with derived group/id/version
bootstrap_json() {
  local any=0
  while IFS= read -r -d '' f; do
    any=1
    local gid; gid="$(derive_group_json "$f")"
    local ver; ver="$(derive_semver_from_group "$gid")"
    local id;  id="$(derive_artifactId_json "$f")"
    local sfx; sfx="$(suffix_for_type JSON)"
    local final_id="${id}${sfx}"
    log "JSON -> ${final_id} (group='${gid}'${ver:+, version=${ver}}) from $(basename "$f")"
    post_artifact_v3 "${gid}" "${final_id}" "JSON" "$f" "${ver}"
  done < <(walk_files '*.json')
  (( any == 1 )) || log "No .json files found in ${SCHEMA_DIR}"
}

# Discovers .proto files and posts them with derived group/id/version
bootstrap_proto() {
  local any=0
  while IFS= read -r -d '' f; do
    any=1
    local gid; gid="$(derive_group_proto "$f")"
    local ver; ver="$(derive_semver_from_group "$gid")"
    local id;  id="$(derive_artifactId_proto "$f")"
    local sfx; sfx="$(suffix_for_type PROTOBUF)"
    local final_id="${id}${sfx}"
    log "PROTOBUF -> ${final_id} (group='${gid}'${ver:+, version=${ver}}) from $(basename "$f")"
    post_artifact_v3 "${gid}" "${final_id}" "PROTOBUF" "$f" "${ver}"
  done < <(walk_files '*.proto')
  (( any == 1 )) || log "No .proto files found in ${SCHEMA_DIR}"
}

# Validates dependencies, waits for registry, bootstraps all types, and optionally execs CMD
main() {
  need_cmd curl
  need_cmd jq
  [[ -d "${SCHEMA_DIR}" ]] || fail "Schema directory not found: ${SCHEMA_DIR}"

  log "Using schema directory: ${SCHEMA_DIR}"
  log "Default fallback group: ${REGISTRY_FALLBACK_GROUP}"
  log "ArtifactId suffix by type: ${ARTIFACT_ID_SUFFIX_BY_TYPE}"
  log "Resolve version from namespace: ${RESOLVE_VERSION_FROM_NAMESPACE}"
  wait_for_registry
  bootstrap_avro
  bootstrap_json
  bootstrap_proto
  log "Schema bootstrap complete."

  if (( $# )); then
    exec "$@"
  fi
}

main "$@"
