# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM valkey/valkey:9.1.0@sha256:8e8d64b405ce18f41b8e5ee20aa4687a8ed0022d1298f2ce31cdcf3a76e09411

ENV VALKEY_PASSWORD=""

ENTRYPOINT ["sh", "-c", "exec valkey-server --requirepass \"$VALKEY_PASSWORD\" --save '' --appendonly no"]
