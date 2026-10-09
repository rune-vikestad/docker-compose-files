# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM apache/kafka-native:4.3.1@sha256:2885898ba17065023f1bd605f3a81efcfa986014f062b73b91ef5462485f9060

# Docker copies a directory's ownership into a new named volume, so pre-creating the data
# directory as appuser is what makes the volume mounted over it writable by Kafka.
USER root
RUN mkdir -p /var/lib/kafka/data && chown -R appuser:appuser /var/lib/kafka
USER appuser
