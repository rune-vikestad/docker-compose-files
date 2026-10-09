# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/mimir:3.2.2@sha256:04068a0a838b6efe9449a04c1d6acd74c7438ac6073dfcbb99c29892647525e3

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
