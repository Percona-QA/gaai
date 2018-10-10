#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

BASEDIR=/dev/shm/MS210818-mysql-8.0.12-linux-x86_64-opt  # Must be in /dev/shm (tmps) or ramfs to eliminte disk I/O & high latency
PERCONAQADIR=/home/roel/percona-qa

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

# SQL Init/setup
${BASEDIR}/bin/mysql -A -uroot -S${BASEDIR}/socket.sock --force --binary-mode test < ${SOURCEDIR}/gaai_init.sql #> /tmp/gaai_init.log 2>&1

# SQL Run (sysbench)
sysbench ${SOURCEDIR}/gaai.lua --sql_file=${SOURCEDIR}/gaai.sql --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-ignore-errors=all --threads=100 --time=0 --thread-stack-size=64K --verbosity=3 --percentile=95 --report-interval=1 --mysql-socket=${BASEDIR}/socket.sock run
