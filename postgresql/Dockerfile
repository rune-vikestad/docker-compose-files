# syntax=docker/dockerfile:1.7

ARG POSTGRES_VERSION=17.6

FROM postgres:${POSTGRES_VERSION}

COPY --chown=10001:10001  ./docker-entrypoint-initdb.d/*.sql /docker-entrypoint-initdb.d/
