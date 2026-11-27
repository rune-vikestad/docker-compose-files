# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/loki:3.7@sha256:4c86f2ad5003304c8da84d29da2279b04eb999d716f8089c88e4fa4a44b0781e

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]
