#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-02

DIR="/media/flash"
logger -p local0.info "'$0' flash device '$1' removed 0161392a-b4d1-11e9-ba84-080027858e30"

if [[ -z $1 ]]; then
    echo "Error: command line argument \$1 does not present"
    logger -p local0.err "'$0' first command line argument does not present 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$  ]]; then
    echo "Error: wrong command line argument '$1'. Must be sd[b-z][1-9]" >&2
    logger -p local0.err "'$0' Error: wrong command line argument '$1'. Must be sd[b-z][1-9] 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

if [[ -b /dev/$1 ]]; then
    echo "Error: device '/dev/$1' still exists"
    logger -p local0.err "'$0' Error: device '/dev/$1' still exists 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

mount -l | grep -Pi "${DIR}/$1"
if [[ $? -eq 0 ]]; then
    echo "Warnign: direcory '${DIR}/$1' is still mounted. Unmounting." >&2
    logger -p local0.warning "'$0' Error: direcory '${DIR}/$1' is still mounted. Unmounting. 0161392a-b4d1-11e9-ba84-080027858e30"
    umount ${DIR}/$1
    mount -l | grep -Pi "${DIR}/$1"
    if [[ $? -eq 0 ]]; then
        echo "Error: could not unmount directory '${DIR}/$1'." >&2
        logger -p local0.err "'$0' Error: could not unmount directory '${DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
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
if [[ -d ${DIR}/$1 ]]; then
    echo "Info: directory '${DIR}/$1' exists. Removing it"
    rmdir ${DIR}/$1
    if [[ -d ${DIR}/$1 ]]; then
        echo "Error: could not remove '${DIR}/$1'" >&2
        logger -p local0.err "'$0' Error: could not remove '${DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi


