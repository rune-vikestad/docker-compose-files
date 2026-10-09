# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM grafana/loki:3.7@sha256:191d4fdfb7264f16989f0a57f320872620a5a7c2ceeec6229212c4190ec49b86

COPY --chown=10001:10001 ./etc/loki/ /etc/loki/

CMD ["-target=all", "-config.file=/etc/loki/local-config.yaml", "-log.level=info"]
