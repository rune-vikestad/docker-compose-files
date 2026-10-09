# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM postgres:18.4@sha256:775a0820dd34e907ec63277e388d145056d427548e461d7953a070edb5de3a3a

COPY --chown=10001:10001  ./docker-entrypoint-initdb.d/*.sql /docker-entrypoint-initdb.d/
