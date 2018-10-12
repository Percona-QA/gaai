#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

# Setup
# Use a server with at least 8 threads, and at least 32GB of memory
# Make sure to have the tarball expanded in /dev/shm (tmpfs), i.e. /dev/shm/mysql-5.7.23-linux-x86_64-opt

#BASEDIR=/sdc/MS101018-mysql-5.7.23-linux-x86_64-opt
BASEDIR=/dev/shm/MS101018-mysql-5.7.23-linux-x86_64-opt
PERCONAQADIR=/home/roel/percona-qa
REPORT_INTERVAL=1
WARMUP_TIME=20     # In seconds
TABLESIZE=1000000
NROFTABLES=5
THREADS=5
MYSQLD_PRECONFIG="--innodb-buffer-pool-size=5242880 --table-open-cache=1 --innodb-io-capacity=100 --innodb-io-capacity-max=100000 --innodb-thread-concurrency=1 --innodb-concurrency-tickets=1 --innodb-flush-neighbors=2 --innodb-log-write-ahead-size=512 --innodb-lru-scan-depth=100 --innodb-random-read-ahead=1 --innodb-read-ahead-threshold=0 --innodb-commit-concurrency=1 --innodb-change-buffer-max-size=0 --innodb-change-buffering=none"

if [ ! -r $PERCONAQADIR/startup.sh ]; then
  echo "Assert: could not locate startup.sh in PERCONAQADIR (set to $PERCONAQADIR), please fetch percona-qa like this;"
  echo "cd ~ && git clone --depth=1 https://github.com/Percona-QA/percona-qa.git"
  exit 1
fi

if [ ! -r $BASEDIR/bin/mysqld ]; then
  echo "Assert: could not locate mysqld in BASEDIR (set to $BASEDIR), please fetch a tarball (.tar.gz) of MySQL or Percona Server"
  exit 1
fi 

if [ "$(which sysbench)" == "" ]; then
  echo "Assert: could not locate sysbench. Best to install it from the Percona Repo like this;"
  echo "1) Configure the Percona Repo following https://www.percona.com/doc/percona-repo-config/apt-repo.html (or yum equivalent)"
  echo "2) sudo apt-get install sysbench   # or yum equivalent"
  exit 1
fi

if [ "$(echo $(which script))" == "" ]; then
  echo "Assert: could not locate the Linux script/typescript utility. Please install the util-linux package as follows:"
  echo "sudo apt-get install util-linux   # or yum equivalent"
  exit 1
fi

which script

# Server startup
SOURCEDIR=${PWD}
cd ${BASEDIR}
./stop 2>/dev/null
$PERCONAQADIR/startup.sh
./start ${MYSQLD_PRECONFIG}
cd ${SOURCEDIR}

# OS Config
ulimit -u 10000
ulimit -n 10000

# Cleanup
rm -f gaai-sb.log.old gaai.qps gaai.time gaai-ga.log gaai.best
mv gaai-sb.log gaai-sb.log.old

# Sysbench Prepare (creates tables)
sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=innodb --table-size=${TABLESIZE} --tables=${NROFTABLES} --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-socket=${BASEDIR}/socket.sock prepare

# Setup Background Sysbench Run (writes qps output ever ${REPORT_INTERVAL} seconds to gaai-sb.log in sysbench output format)
script -q -f gaai-sb.log -c "./gaai-sb.sh ${REPORT_INTERVAL} ${THREADS} ${TABLESIZE} ${NROFTABLES} ${BASEDIR} gaai-sb" &

# Genetic Algorithm Artificial Intelligence Database Performance Tuning (actual optimization using gaai.qps as input for the GA)
# This uses sysbench as the lua interpreter only which makes it easy to connect to the already running MySQL server
sysbench ./gaai-ga.lua --sleep_time=${WARMUP_TIME} --mysql-db=test --mysql-user=root --db-driver=mysql --threads=1 --time=0 --verbosity=3 --mysql-socket=${BASEDIR}/socket.sock run
