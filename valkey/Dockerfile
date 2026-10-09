# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM valkey/valkey:9.1.2@sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd

ENV VALKEY_PASSWORD=""

ENTRYPOINT ["sh", "-c", "exec valkey-server --requirepass \"$VALKEY_PASSWORD\" --save '' --appendonly no"]
