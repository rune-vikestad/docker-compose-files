# syntax=docker/dockerfile:1.7
ARG ALPINE_VERSION=3.20
ARG STEP_CA_VERSION=0.28.4

# Build stage on Alpine to get jq + libonig
FROM alpine:${ALPINE_VERSION} AS tools
RUN apk add --no-cache jq oniguruma

# Final step-ca image
FROM smallstep/step-ca:${STEP_CA_VERSION}
USER root
# Copy jq and the oniguruma library it needs
COPY --from=tools /usr/bin/jq /usr/local/bin/jq
COPY --from=tools /usr/lib/libonig.so.5 /usr/lib/libonig.so.5

ENV STEPPATH=/home/step
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh \
 && mkdir -p /home/step \
 && chown -R 10001:0 /home/step

USER 10001
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
