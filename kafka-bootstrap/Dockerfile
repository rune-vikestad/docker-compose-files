# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.22.2
ARG KAFKA_VERSION=4.0.0
ARG SCALA_VERSION=2.13

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache bash jq curl tar openjdk21-jre-headless

ARG KAFKA_VERSION
ARG SCALA_VERSION
ENV KAFKA_HOME=/opt/kafka \
    PATH=/opt/kafka/bin:$PATH \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk
RUN curl -fsSL "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" -o /tmp/kafka.tgz \
 && mkdir -p /opt \
 && tar -xzf /tmp/kafka.tgz -C /opt \
 && mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka \
 && rm -f /tmp/kafka.tgz

ENV BOOTSTRAP_SERVERS="kafka:9092" \
    DEFAULT_PARTITIONS="1" \
    DEFAULT_REPLICATION_FACTOR="1" \
    WAIT_MAX_TRIES="60"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Always bake local ./topics into the fixed directory
COPY ./topics/ /usr/local/share/kafka-bootstrap

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
