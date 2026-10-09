# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

ARG KAFKA_VERSION=4.3.1
ARG SCALA_VERSION=2.13

FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11

RUN apk add --no-cache bash jq curl tar openjdk21-jre-headless

ARG KAFKA_VERSION
ARG SCALA_VERSION
ENV KAFKA_HOME=/opt/kafka \
    PATH=/opt/kafka/bin:$PATH \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# downloads.apache.org carries only the current release of each line, so a version that has been superseded
# by a patch is served from archive.apache.org instead. Trying both means an existing pin keeps building on
# the day a new Kafka ships, rather than 404ing with nothing to say why.
RUN set -eu; \
    tarball="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
    found=0; \
    for base in "https://downloads.apache.org" "https://archive.apache.org/dist"; do \
        url="${base}/kafka/${KAFKA_VERSION}/${tarball}"; \
        echo "Fetching ${url}"; \
        if curl -fsSL "${url}" -o /tmp/kafka.tgz && curl -fsSL "${url}.sha512" -o /tmp/kafka.sha512; then found=1; break; fi; \
        echo "Not available at ${base}"; \
    done; \
    if [ "${found}" -ne 1 ]; then \
        echo "ERROR: ${tarball} was not found on downloads.apache.org or archive.apache.org" >&2; \
        exit 1; \
    fi; \
    expected="$(tr -d '[:space:]' < /tmp/kafka.sha512 | grep -oiE '[0-9a-f]{128}' | head -1 | tr 'A-Z' 'a-z')"; \
    actual="$(sha512sum /tmp/kafka.tgz | cut -d' ' -f1)"; \
    if [ -z "${expected}" ]; then \
        echo "ERROR: no sha512 could be read from ${tarball}.sha512" >&2; \
        exit 1; \
    fi; \
    if [ "${expected}" != "${actual}" ]; then \
        echo "ERROR: sha512 mismatch for ${tarball}" >&2; \
        echo "  expected ${expected}" >&2; \
        echo "  actual   ${actual}" >&2; \
        exit 1; \
    fi; \
    echo "Verified sha512 ${actual}"; \
    mkdir -p /opt; \
    tar -xzf /tmp/kafka.tgz -C /opt; \
    mv "/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" /opt/kafka; \
    rm -f /tmp/kafka.tgz /tmp/kafka.sha512

ENV BOOTSTRAP_SERVERS="kafka:9092" \
    SCHEMA_REGISTRY_URL="http://apicurio-registry:8080/apis/ccompat/v7" \
    DEFAULT_PARTITIONS="1" \
    DEFAULT_REPLICATION_FACTOR="1" \
    WAIT_MAX_TRIES="60"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY ./topics/ /usr/local/share/kafka-bootstrap/topics
COPY ./schemas/ /usr/local/share/kafka-bootstrap/schemas

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
