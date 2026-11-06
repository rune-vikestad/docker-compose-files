# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM alpine:3.24.4@sha256:93b41ef40b1677fce8fcc64ff4af09daddfacf5040afde618bc46c1e2d1cc7d4

RUN apk add --no-cache bash curl jq

ENV REGISTRY_URL="http://apicurio-registry:8080/apis/registry/v3" \
    REGISTRY_FALLBACK_GROUP="default" \
    SCHEMA_DIR="/usr/local/share/apicurio/schemas"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY ./schemas/ /usr/local/share/apicurio/schemas

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD []
