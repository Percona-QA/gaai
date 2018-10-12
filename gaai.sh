#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

# Setup
# Use a server with at least 8 threads, and at least 32GB of memory
# Make sure to have the tarball expanded in /dev/shm (tmpfs), i.e. /dev/shm/mysql-5.7.23-linux-x86_64-opt

#BASEDIR=/sdc/MS101018-mysql-5.7.23-linux-x86_64-opt
BASEDIR=/dev/shm/MS101018-mysql-5.7.23-linux-x86_64-opt
PERCONAQADIR=/home/roel/percona-qa
REPORT_INTERVAL=2
TABLESIZE=1000000  # 10000000
NROFTABLES=4       # 4
THREADS=5
MYSQLD_PRECONFIG="--innodb-buffer-pool-size=5242880 --innodb-buffer-pool-chunk-size=1048576 --table-open-cache=1 --innodb-io-capacity=100 --innodb-io-capacity-max=100000 --innodb-thread-concurrency=1 --innodb-concurrency-tickets=1 --innodb-flush-neighbors=2 --innodb-log-write-ahead-size=512 --innodb-lru-scan-depth=100 --innodb-random-read-ahead=1 --innodb-read-ahead-threshold=0 --innodb-commit-concurrency=1 --innodb-change-buffer-max-size=0 --innodb-change-buffering=none"

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
./start ${MYSQLD_PRECONFIG}

# OS Config
ulimit -u 10000
ulimit -n 10000

# Sysbench Prepare
sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=innodb --table-size=${TABLESIZE} --tables=${NROFTABLES} --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${BASEDIR}/socket.sock prepare

# Sysbench Run in background
sysbench /usr/share/sysbench/oltp_read_write.lua --report-interval=${REPORT_INTERVAL} --time=0 --events=0 --index_updates=10 --non_index_updates=10 --distinct_ranges=15 --order_ranges=15 --threads=${THREADS} --table-size=${TABLESIZE} --tables=${NROFTABLES} --percentile=95 --verbosity=3 --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${BASEDIR}/socket.sock run
