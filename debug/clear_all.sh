#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-05

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script removes all uploaded files from the server using rsync"
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
source ${PWD}/../conf/rsync_conf.sh
source ${PWD}/../conf/mount_conf.sh

RSYNC_STATUS=`rsync -a --delete ${PWD}/emptydir/ rsync://${RSYNC_HOST}/${RSYNC_PATH}/ 2>&1`
if [[ $? -ne 0 ]]; then
    logger -sp local0.err "'$0'. Error rsync could not clear server: ${RSYNC_STATUS}."
    exit 1
fi
PSQL_STATUS=`psql -c "TRUNCATE load_status"`
if [[ ! ${PSQL_STATUS} =~ 'TRUNCATE TABLE' ]]; then
    logger -sp local0.err "'$0'. Could not truncate load_status table: ${PSQL_STATUS}."
    exit 1
fi

echo "DONE"
exit 0



