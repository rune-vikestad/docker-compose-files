# syntax=docker/dockerfile:1.7

ARG GRAFANA_TEMPO_VERSION=2.8.2

FROM grafana/tempo:${GRAFANA_TEMPO_VERSION}

COPY --chown=10001:10001 ./etc/tempo/ /etc/tempo/

CMD ["-config.file=/etc/tempo/config.yaml"]