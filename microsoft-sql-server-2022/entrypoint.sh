#!/bin/bash

sleep 30

./configure.sh &

/opt/mssql/bin/sqlservr
