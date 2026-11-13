# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/mimir:3.2.5@sha256:245ce851e2f5d27db6bd37720d9ab12bcb017f4b4e20340d9b58266435dbe4b6

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
