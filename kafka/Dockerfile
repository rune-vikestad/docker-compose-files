# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM apache/kafka-native:4.3.1@sha256:2885898ba17065023f1bd605f3a81efcfa986014f062b73b91ef5462485f9060

# Docker copies a directory's ownership into a new named volume, so pre-creating the data
# directory as appuser is what makes the volume mounted over it writable by Kafka.
USER root
RUN mkdir -p /var/lib/kafka/data && chown -R appuser:appuser /var/lib/kafka
USER appuser
