FROM mcr.microsoft.com/mssql/server:2022-latest

USER root
RUN mkdir -p /var/log/docker && chown -R mssql:mssql /var/log/docker
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint.sh

USER mssql
ENTRYPOINT ["/docker-entrypoint.sh"]
