# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM mcr.microsoft.com/mssql/server:2025-latest@sha256:2b5b581621126574f3d1f75e78d3eebe8d05aedb59ad0cfdf9aa42cb0634d726

USER root
RUN mkdir -p /var/log/docker && chown -R mssql:mssql /var/log/docker
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint.sh

USER mssql
ENTRYPOINT ["/docker-entrypoint.sh"]
