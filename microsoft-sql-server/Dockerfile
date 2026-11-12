# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM mcr.microsoft.com/mssql/server:2025-latest@sha256:05644dad1266ca3d445d1e8f6d2ebb9a6a03df9a39376e0f7b48917356dca9d9

USER root
RUN mkdir -p /var/log/docker && chown -R mssql:mssql /var/log/docker
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint.sh

USER mssql
ENTRYPOINT ["/docker-entrypoint.sh"]
