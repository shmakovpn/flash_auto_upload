#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-02
# This script processes the disk insertion event.

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script processes the disk insertion event"
        echo "Use '$0 [-h]'"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    echo "Error: command line argument \$1 does not present"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$ ]]; then
    echo "Error: wrong command line argument '$1'. Must be sd[b-z][1-9]"
    exit 1
fi
# end command line arguments

PWD=`dirname $0`
if [[ ! $PWD =~ ^\/ ]]; then
    PWD=`pwd`"/"`echo ${PWD} | sed -re 's/^\.\///'`
fi

source ${PWD}/conf/mount_conf.sh

logger -p local0.info "'$0' flash device '$1' added 0161392a-b4d1-11e9-ba84-080027858e30"

if [[ ! -b /dev/$1 ]]; then
    echo "Error: file '/dev/$1' does not exist" >&2
    logger -p local0.err "'$0' Error: file '/dev/$1' does not exist 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
if [[ ! -d ${MOUNT_DIR} ]]; then
    echo "Info: directory '${MOUNT_DIR}' does not exist. Creating it"
    mkdir -p ${MOUNT_DIR}
    if [[ ! -d ${MOUNT_DIR} ]]; then
        echo "Error: could not create '${MOUNT_DIR}'" >&2
        logger -p local0.err "'$0' Error: could not create '${MOUNT_DIR}' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi
if [[ ! -d ${MOUNT_DIR}/$1 ]]; then
    echo "Info: directory '${MOUNT_DIR}/$1' does not exist. Creating it"
    mkdir -p ${MOUNT_DIR}/$1
    if [[ ! -d ${MOUNT_DIR}/$1 ]]; then
        echo "Error: could not create '${MOUNT_DIR}/$1'" >&2
        logger -p local0.err "'$0' Error: could not create '${MOUNT_DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi

chown :autoload ${MOUNT_DIR}/$1
chmod g+w ${MOUNT_DIR}/$1

mount -l | grep -Pi "^/dev/$1"
if [[ $? -eq 0 ]]; then
    echo "Error: '/dev/$1' already mounted" >&2
    logger -p local0.err "'$0' Error: '/dev/$1' already mounted 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

mount /dev/$1 ${MOUNT_DIR}/$1
if [[ $? -ne 0 ]]; then
    echo "Error: could not mount '/dev/$1'" >&2
    logger -p local0.err "'$0' Error: could not mount '/dev/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

logger -p local0.info "'$0' flash device '$1' mounted to '${MOUNT_DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"

# starts copy process
${PWD}/copy_starter.sh $1 > /dev/null 1>&2
logger -p local0.info "'$0' copy_starter.sh $1 finished 0161392a-b4d1-11e9-ba84-080027858e30"
