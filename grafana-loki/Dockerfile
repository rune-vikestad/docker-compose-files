# syntax=docker/dockerfile:1.7

ARG GRAFANA_LOKI_VERSION=3.5

FROM grafana/loki:${GRAFANA_LOKI_VERSION}

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

# CMD ["-config.file=/etc/loki/local-config.yaml"]
CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]