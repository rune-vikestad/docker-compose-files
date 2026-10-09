# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM otel/opentelemetry-collector:0.152.1@sha256:c5cde41675a68e392322140d25fa232b4585e4e7fdc5f8c39d61d968bc13dae6

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]
