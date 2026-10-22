# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/tempo:3.1.1@sha256:64e2fbd56d9c2b3412a4b430a58ea59e91a670b1e75f920a0c702213ad145044

COPY --chown=10001:10001 ./etc/tempo/ /etc/tempo/

CMD ["-config.file=/etc/tempo/config.yaml"]
