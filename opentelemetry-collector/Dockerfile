# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM otel/opentelemetry-collector:0.163.2@sha256:63e5e8eccf4268be02388ba9f2dc36b80b5e47721291293411c0e83152d75bda

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]
