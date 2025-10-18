# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.22.2
ARG REGISTRY_URL="http://apicurio-registry:8080/apis/registry/v3"
ARG REGISTRY_GROUP="default"

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache bash curl jq

ENV REGISTRY_URL="${REGISTRY_URL}" \
    REGISTRY_GROUP="${REGISTRY_GROUP}" \
    SCHEMA_DIR="/usr/local/share/apicurio/schemas" \
    ARTIFACT_ID_SUFFIX_BY_TYPE="true"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY ./schemas/ /usr/local/share/apicurio/schemas

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD []
