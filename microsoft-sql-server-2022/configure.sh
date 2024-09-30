#!/bin/bash

export INITDB_FOLDER="/docker-entrypoint-initdb.d"
export INITDB_LOG_FILE="/var/log/docker/mssql-serverserver-2022-initdb.log"
export STATUS=1

# Is the server ready yet?
i=0
while [[ $STATUS -ne 0 ]] && [[ $i -lt 60 ]]; do
	i=$i+1
	/opt/mssql-tools18/bin/sqlcmd -C -l 1 -t 1 -U sa -P ${MSSQL_SA_PASSWORD} -Q "SELECT 1" >> /dev/null
	STATUS=$?
	sleep 1
done

# We've waited for 60 iterations; the SQL Server should be ready by now
if [ $STATUS -ne 0 ]; then 
	exit 1
fi

# Run SQL scripts found in $INITDB_FOLDER
find $INITDB_FOLDER -maxdepth 1 -name *.sql -exec /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P ${MSSQL_SA_PASSWORD} -d master -i {} \;
