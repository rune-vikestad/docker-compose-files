# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/loki:3.7@sha256:b43c257ccfc925d4a50b8717cac61a3b51df8c48d01847936057e5c4075a24a7

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]
