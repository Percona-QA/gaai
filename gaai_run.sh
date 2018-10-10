#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

BASEDIR=/sda/MS050918-mysql-5.7.23-linux-x86_64-debug
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

SOURCEDIR=${PWD}
cd $BASEDIR
./stop 2>/dev/null
$PERCONAQADIR/

sysbench ${SOURCEDIR}/gaai2.lua --sql_file=${PWD}/gaai.sql --mysql-db=test --mysql-user=root --db-driver=mysql --mysql-ignore-errors=all --threads=100 --mysql-socket=/sda/MS050918-mysql-5.7.23-linux-x86_64-debug/socket.sock run
