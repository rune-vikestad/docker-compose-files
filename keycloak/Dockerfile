# syntax=docker/dockerfile:1.7

ARG KEYCLOAK_VERSION=latest
ARG STEP_CLI_VERSION=0.26.0

# Get Smallstep CLI
FROM smallstep/step-cli:${STEP_CLI_VERSION} AS step-cli

# Final Keycloak image
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

# We need to bind to port 80 for ACME HTTP-01, so run as root.
USER root

# Tools + step CLI
COPY --from=step-cli /usr/bin/step /usr/local/bin/step

# Keycloak base image is UBI; microdnf available. Ignore if already present.
RUN microdnf install -y curl openssl || true

# Copy our entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/entrypoint-with-acme.sh

RUN chmod +x /usr/local/bin/entrypoint-with-acme.sh

# Use our script as entrypoint; CMD is supplied by compose ("start --optimized")
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh.sh"]
