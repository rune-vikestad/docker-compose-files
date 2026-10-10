# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM otel/opentelemetry-collector:0.162.0@sha256:310a800ad69ee430e7c541796852a242c9c7db97aaad4daa5ccf843c525fbdb2

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]
