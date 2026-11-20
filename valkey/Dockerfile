# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM valkey/valkey:9.2.0@sha256:1c2b25b09f354c66fe994733acdf12fcfd4bdf6f3bd92b88a93a70378d884056

ENV VALKEY_PASSWORD=""

ENTRYPOINT ["sh", "-c", "exec valkey-server --requirepass \"$VALKEY_PASSWORD\" --save '' --appendonly no"]
