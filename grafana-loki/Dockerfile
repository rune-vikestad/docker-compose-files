# syntax=docker/dockerfile:1.7

ARG GRAFANA_LOKI_VERSION=3.3.2

FROM grafana/loki:${GRAFANA_LOKI_VERSION}

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-config.file=/etc/loki/local-config.yaml"]