# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/mimir:3.2.4@sha256:e4ff85d922c7c0a5131576d2659a1b98b3abfd73c92448dccf8ad3a6049a7ed8

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
