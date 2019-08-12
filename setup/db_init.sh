#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-07
# This scripts creates needable tables in autoload server Postgresql database

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script creates needable tables in autoload server Postgresql database"
        echo "Use '$0 [-h]'"
        echo "    [-h] show this help message"
        exit 0
    fi
done
# end command line arguments

PWD=`dirname $0`
if [[ ! $PWD =~ ^\/ ]]; then
    PWD=`pwd`"/"`echo ${PWD} | sed -re 's/^\.\///'`
fi

source ${PWD}/../conf/db_conf.sh

# begin command line arguments
for arg in "$@"; do
    if [[ ${arg} =~ '-c' ]]; then
        PGSQL_STATUS=`psql -c "DROP TABLE IF EXISTS load_status" 2>&1`
        if [[ $? -ne 0 ]]; then
            echo "Error. DB. Could not DROP TABLE IF EXISTS load_status: ${PGSQL_STATUS}"
            exit 1
        fi
    fi
done
# end command line arguments

PGSQL_STATUS=`psql -c "CREATE TABLE IF NOT EXISTS load_status (\
                 md5 UUID NOT NULL PRIMARY KEY,\
                 in_file_name CHARACTER VARYING(200) NOT NULL,\
                 out_file_name CHARACTER VARYING(200) NOT NULL,\
                 status INTEGER NOT NULL DEFAULT 1,\
                 begin_ts TIMESTAMPTZ NOT NULL DEFAULT now(),\
                 end_ts TIMESTAMPTZ
             )" 2>&1`
if [[ $? -ne 0 ]]; then
    echo "Error. DB. Could not 'CREATE TABLE IF NOT EXISTS load_status': ${PGSQL_STATUS}"
    exit 1
else
    echo "DONE"
fi

