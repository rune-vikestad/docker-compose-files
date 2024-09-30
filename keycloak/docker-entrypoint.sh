#!/usr/bin/env bash
set -euo pipefail

# --- required env ---
: "${KC_HOSTNAME:?missing KC_HOSTNAME}"
: "${STEP_CA_URL:?missing STEP_CA_URL}"
: "${STEP_CA_ROOT:?missing STEP_CA_ROOT}"
: "${STEP_ACME_PROVISIONER:?missing STEP_ACME_PROVISIONER}"

# --- optional env ---
: "${STEP_ACME_CONTACT:=mailto:admin@example.com}"
: "${STEP_CERT_NOT_AFTER:=2160h}"   # 90 days

CRT="${KC_HTTPS_CERTIFICATE_FILE:-/opt/keycloak/conf/tls.crt}"
KEY="${KC_HTTPS_CERTIFICATE_KEY_FILE:-/opt/keycloak/conf/tls.key}"

issue_or_renew() {
  echo "[acme] Requesting certificate for ${KC_HOSTNAME} via ACME provisioner '${STEP_ACME_PROVISIONER}'"
  
  # Standalone HTTP-01 server binds to :80 inside this container.
  # '-f' overwrites existing files when renewing.
  step ca certificate \
    --provisioner "${STEP_ACME_PROVISIONER}" \
    --ca-url "${STEP_CA_URL}" \
    --root "${STEP_CA_ROOT}" \
    --contact "${STEP_ACME_CONTACT}" \
    --standalone \
    --http-listen ":80" \
    --not-after "${STEP_CERT_NOT_AFTER}" \
    -f \
    --san "${KC_HOSTNAME}" \
    "${KC_HOSTNAME}" "${CRT}" "${KEY}"

  chmod 0400 "${KEY}"
  echo "[acme] Certificate ready: ${CRT}"
}

# Wait until step-ca is reachable (ACME directory & HTTPS)
for i in {1..30}; do
  if curl -sSk "${STEP_CA_URL}/health" >/dev/null 2>&1; then break; fi
  echo "[acme] Waiting for step-ca..."
  sleep 1
done

# Ensure we have a cert on startup; renew if expiring within 72h
if [ ! -s "${CRT}" ] || [ ! -s "${KEY}" ]; then
  issue_or_renew
else
  echo "[acme] Existing certificate found; attempting renewal if near expiry..."
  if command -v openssl >/dev/null 2>&1; then
    end=$(openssl x509 -enddate -noout -in "${CRT}" | cut -d= -f2 || true)
    if [ -n "${end}" ] && date -d "${end}" -u +"%s" >/dev/null 2>&1; then
      now=$(date -u +"%s"); exp=$(date -d "${end}" -u +"%s")
      if [ $((exp - now)) -lt $((72*3600)) ]; then
        echo "[acme] Certificate expires soon; renewing..."
        issue_or_renew
      fi
    fi
  fi
fi

# Start Keycloak (listening on 8443 with the PEMs we just created)
exec /opt/keycloak/bin/kc.sh "$@"
