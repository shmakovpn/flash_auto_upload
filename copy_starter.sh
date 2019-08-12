#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-08

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script starts copying files from a removable media to server"
        echo "Use '$0 [-h] disk_name'"
        echo "    disk_name the name of mounted removable drive (like sdb1, sdc1, ..)"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    logger -sp local0.err "'$0'. Error. A first command line argument does not present. See '$0 -h' 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$ ]]; then
    logger -sp local0.err "'$0'. Error: wrong command line argument '$1'. Must be sd[b-z][1-9] 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
# end command line arguments

PWD=`dirname $0`
if [[ ! $PWD =~ ^\/ ]]; then
    PWD=`pwd`"/"`echo ${PWD} | sed -re 's/^\.\///'`
fi

PS_STDOUT=`ps aux | grep "copy_files.sh" | grep $1 | grep -v grep`
PS_STATUS=$?
logger -sp local0.info "'$0'. ps_status=${PS_STATUS}. ps_stdout='${PS_STDOUT}'. 0161392a-b4d1-11e9-ba84-080027858e30"
if [[ ${PS_STATUS} -eq 0 ]]; then
    logger -sp local0.info "'$0'. Info. Copying is already running. 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

${PWD}/copy_files.sh $1 > /dev/null 1>&2
logger -p local0.info "'$0' copy_files.sh $1 finished 0161392a-b4d1-11e9-ba84-080027858e30"

