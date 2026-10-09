# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM postgres:18.6@sha256:74935e72241653ca55e0414067e6d8763aceb8a810eb51b452253ec3dcfc4336

COPY --chown=10001:10001  ./docker-entrypoint-initdb.d/*.sql /docker-entrypoint-initdb.d/
