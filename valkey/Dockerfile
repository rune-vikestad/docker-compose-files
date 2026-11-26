# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM valkey/valkey:9.2.1@sha256:169567d6288e5f08aa141847c0c3e0864a32e727682ca6f052a20567c7103ef8

ENV VALKEY_PASSWORD=""

ENTRYPOINT ["sh", "-c", "exec valkey-server --requirepass \"$VALKEY_PASSWORD\" --save '' --appendonly no"]
