# syntax=docker/dockerfile:1.7

ARG GRAFANA_VERSION=12.1.1

FROM grafana/grafana-oss:${GRAFANA_VERSION}

COPY --chown=10001:10001 ./etc/grafana/ /etc/grafana/