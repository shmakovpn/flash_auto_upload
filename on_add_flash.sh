#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-02
if [[ -z $1 ]]; then
    echo "Error: command line argument \$1 does not present"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$  ]]; then
    echo "Error: wrong command line argument '$1'. Must be sd[b-z][1-9]"
    exit 1
fi

DIR="/media/flash"

logger -p local0.info "'$0' flash device '$1' added 0161392a-b4d1-11e9-ba84-080027858e30"

if [[ ! -b /dev/$1 ]]; then
    echo "Error: file '/dev/$1' does not exist" >&2
    logger -p local0.err "'$0' Error: file '/dev/$1' does not exist 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
if [[ ! -d ${DIR} ]]; then
    echo "Info: directory '${DIR}' does not exist. Creating it"
    mkdir -p ${DIR}
    if [[ ! -d ${DIR} ]]; then
        echo "Error: could not create '${DIR}'" >&2
        logger -p local0.err "'$0' Error: could not create '${DIR}' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi
if [[ ! -d ${DIR}/$1 ]]; then
    echo "Info: directory '${DIR}/$1' does not exist. Creating it"
    mkdir -p ${DIR}/$1
    if [[ ! -d ${DIR}/$1 ]]; then
        echo "Error: could not create '${DIR}/$1'" >&2
        logger -p local0.err "'$0' Error: could not create '${DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi

chown :autoload ${DIR}/$1
chmod g+w ${DIR}/$1

mount -l | grep -Pi "^/dev/$1"
if [[ $? -eq 0 ]]; then
    echo "Error: '/dev/$1' already mounted" >&2
    logger -p local0.err "'$0' Error: '/dev/$1' already mounted 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

mount /dev/$1 ${DIR}/$1
if [[ $? -ne 0 ]]; then
    echo "Error: could not mount '/dev/$1'" >&2
    logger -p local0.err "'$0' Error: could not mount '/dev/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

logger -p local0.info "'$0' flash device '$1' mounted to '${DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
