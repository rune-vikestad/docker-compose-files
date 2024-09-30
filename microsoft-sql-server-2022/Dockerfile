FROM mcr.microsoft.com/mssql/server:2022-latest

USER root
RUN mkdir -p /var/log/docker
RUN chown mssql:mssql /var/log/docker

RUN touch /var/log/docker/mssql-serverserver-2022-initdb.log
COPY entrypoint.sh /entrypoint.sh
COPY configure.sh /configure.sh

ENTRYPOINT ["./entrypoint.sh"]