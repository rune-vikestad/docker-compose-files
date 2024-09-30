#!/usr/bin/env bash

set -euo pipefail

: "${STEPPATH:=/home/step}"
: "${STEP_CA_NAME:=Untrustworthy}"
: "${STEP_CA_PROVISIONER_EMAIL:=pki@example.com}"
: "${STEP_CA_HOST:=step-ca}"
: "${STEP_CA_PORT:=9000}"
: "${STEP_CA_PASSWORD_FILE:=/run/secrets/step-ca-password}"

CA_JSON_FILE="${STEPPATH}/config/ca.json"
CA_RUNTIME_PASSWORD_FILE="${STEPPATH}/secrets/password"  
CA_ROOT_CRT="${STEPPATH}/certs/root_ca.crt"
CA_ROOT_KEY="${STEPPATH}/secrets/root_ca_key"
CA_INTERMEDIATE_CRT="${STEPPATH}/certs/intermediate_ca.crt"
CA_INTERMEDIATE_KEY="${STEPPATH}/secrets/intermediate_ca_key"

umask 077

mkdir -p "${STEPPATH}/secrets"

# Sync the secret into the runtime password file (owned by the running user)
if [ -s "${STEP_CA_PASSWORD_FILE}" ]; then
  cp "${STEP_CA_PASSWORD_FILE}" "${CA_RUNTIME_PASSWORD_FILE}"
  chmod 0400 "${CA_RUNTIME_PASSWORD_FILE}" || true
fi

if [ ! -f "$CA_JSON_FILE" ]; then
  echo "[step-ca] Initializing CA…"

  # 
  # Replace --no-db with --acme for ACME support
  #
  step ca init \
    --name "${STEP_CA_NAME}" \
    --dns "${STEP_CA_HOST}" \
    --address ":${STEP_CA_PORT}" \
    --provisioner "${STEP_CA_PROVISIONER_EMAIL}" \
    --with-ca-url "https://${STEP_CA_HOST}:${STEP_CA_PORT}" \
    --deployment-type standalone \
    --no-db \
    --password-file "${CA_RUNTIME_PASSWORD_FILE}"

  echo "[step-ca] CA initialized."
fi

# Print Root CA certificate details
echo "[step-ca] Root CA certificate:"
step certificate inspect --format=text "${CA_ROOT_CRT}" || true

# Print Intermediate CA certificate details
echo "[step-ca] Intermediate CA certificate:"
step certificate inspect --format=text "${CA_INTERMEDIATE_CRT}" || true

# Ensure we can start non-interactively
if [ ! -s "${CA_RUNTIME_PASSWORD_FILE}" ]; then
  echo "[step-ca] ERROR: ${CA_RUNTIME_PASSWORD_FILE} is missing or empty; cannot start non-interactively." >&2
  exit 1
fi

exec step-ca --password-file "${CA_RUNTIME_PASSWORD_FILE}" "${CA_JSON_FILE}"
