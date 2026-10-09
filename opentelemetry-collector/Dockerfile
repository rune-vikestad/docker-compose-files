# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM otel/opentelemetry-collector:0.152.1@sha256:c5cde41675a68e392322140d25fa232b4585e4e7fdc5f8c39d61d968bc13dae6

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]
