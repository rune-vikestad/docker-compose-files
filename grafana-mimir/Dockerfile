# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/mimir:3.2.6@sha256:32d79dc873a804d4dbf2724afcbb7b141553b5ed9118f9295972c4bb2982d6fd

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
