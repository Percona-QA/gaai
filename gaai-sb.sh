#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

if [ "$6" != "gaai-sb" ]; then
  echo "This script is not supposed to be run directly. Instead, start gaai.sh after configuring the user configurable variables within it"
else
  sysbench /usr/share/sysbench/oltp_read_write.lua --report-interval=${1} --time=0 --events=0 --index_updates=10 --non_index_updates=10 --distinct_ranges=15 --order_ranges=15 --threads=${2} --table-size=${3} --tables=${4} --percentile=95 --verbosity=3 --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${5}/socket.sock run
fi
