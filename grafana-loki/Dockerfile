# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM grafana/loki:3.7@sha256:0db216b630ae1f348a1584c67f3cead8b4c1fc839169a39501db664744158e28

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]
