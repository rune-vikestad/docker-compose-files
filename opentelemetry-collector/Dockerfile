# syntax=docker/dockerfile:1.7

ARG OPENTELEMETRY_COLLECTOR_VERSION=0.133.0

FROM otel/opentelemetry-collector:${OPENTELEMETRY_COLLECTOR_VERSION}

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]