# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/loki:3.7@sha256:1107dd5274e0ada47e42472b7a7e71f3b2a2fe878878108f3e2f9e51528f0193

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]
