# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM apache/kafka-native:4.4.0@sha256:11fde816adf384402de9f3e57aeaf2c3722ba0671610247817688d07441714b4

# Docker copies a directory's ownership into a new named volume, so pre-creating the data
# directory as appuser is what makes the volume mounted over it writable by Kafka.
USER root
RUN mkdir -p /var/lib/kafka/data && chown -R appuser:appuser /var/lib/kafka
USER appuser
