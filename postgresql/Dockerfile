# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM postgres:18.4@sha256:775a0820dd34e907ec63277e388d145056d427548e461d7953a070edb5de3a3a

COPY --chown=10001:10001  ./docker-entrypoint-initdb.d/*.sql /docker-entrypoint-initdb.d/
