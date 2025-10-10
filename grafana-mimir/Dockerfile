# syntax=docker/dockerfile:1.7

ARG GRAFANA_MIMIR_VERSION=2.17.1

FROM grafana/mimir:${GRAFANA_MIMIR_VERSION}

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]