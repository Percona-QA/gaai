#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

BASEDIR=/sdc/MS101018-mysql-5.7.23-linux-x86_64-opt
PERCONAQADIR=/home/roel/percona-qa
REPORT_INTERVAL=2
THREADS=5

if [ ! -r $PERCONAQADIR/startup.sh ]; then
  echo "Assert: could not locate startup.sh in PERCONAQADIR (set to $PERCONAQADIR), please fetch percona-qa like this;"
  echo "cd ~ && https://github.com/Percona-QA/percona-qa.git"
  exit 1
fi

if [ ! -r $BASEDIR/bin/mysqld ]; then
  echo "Assert: could not locate mysqld in BASEDIR (set to $BASEDIR), please fetch a tarball (.tar.gz) of MySQL or Percona Server"
  exit 1
fi 

if [ "$(which sysbench)" == "" ]; then
  echo "Assert: could not locate sysbench. Best to install it from the Percona Repo like this;"
  echo "1) Configure the Percona Repo following https://www.percona.com/doc/percona-repo-config/apt-repo.html (or yum equivalent)"
  echo "2) apt-get install sysbench   # or yum equivalent"
  exit 1
fi

# Server startup
SOURCEDIR=${PWD}
cd $BASEDIR
./stop 2>/dev/null
$PERCONAQADIR/startup.sh
./start

# OS Config
ulimit -u 10000
ulimit -n 10000

# SQL Init/setup
#${BASEDIR}/bin/mysql -A -uroot -S${BASEDIR}/socket.sock --force --binary-mode test < ${SOURCEDIR}/gaai_init.sql #> /tmp/gaai_init.log 2>&1a
sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=innodb --table-size=10000000 --tables=4 --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${BASEDIR}/socket.sock prepare

# SQL Run (sysbench)
#sysbench ${SOURCEDIR}/gaai.lua --sql_file=${SOURCEDIR}/gaai.sql --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-ignore-errors=all --threads=${THREADS} --time=0 --verbosity=3 --percentile=95 --report-interval=${REPORT_INTERVAL} --mysql-socket=${BASEDIR}/socket.sock run   # --thread-stack-size=64K
sysbench /usr/share/sysbench/oltp_read_write.lua --report-interval=${REPORT_INTERVAL} --time=0 --events=0 --index_updates=10 --non_index_updates=10 --distinct_ranges=15 --order_ranges=15 --threads=${THREADS} --table-size=10000000 --tables=4 --percentile=95 --verbosity=3 --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${BASEDIR}/socket.sock run
