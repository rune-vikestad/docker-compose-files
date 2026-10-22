# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/mimir:3.2.3@sha256:0ed56db7d7713707eff00224ddd4c3096afa6cf1cbe43a6f9391c537f1416099

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
