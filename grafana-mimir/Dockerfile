# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM grafana/mimir:3.0.6@sha256:4508fd612969dfcf4b50276856fd05d5a971b15e494ad53da911b44781446f2b

COPY --chown=10001:10001 ./etc/mimir/ /etc/mimir/

CMD ["-config.file=/etc/mimir/config.yaml"]
