# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM otel/opentelemetry-collector:0.166.0@sha256:5dfb40297a8da893e4e9b6b98d3ddbdd9082f73611170d6381e355e08b235334

COPY --chown=10001:10001 ./etc/otelcol/ /etc/otelcol/

CMD [ "--config=/etc/otelcol/config.yaml" ]
