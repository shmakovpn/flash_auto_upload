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
if [[ ! -d ${DIR} ]]; then
    echo "Info: directory '${DIR}' does not exist. Creating it"
    mkdir -p ${DIR}
    if [[ ! -d ${DIR} ]]; then
        echo "Error: could not create '${DIR}'" >&2
        exit 1
    fi
fi
if [[ ! -d ${DIR}/$1 ]]; then
    echo "Info: directory '${DIR}/$1' does not exist. Creating it"
    mkdir -p ${DIR}/$1
    if [[ ! -d ${DIR}/$1 ]]; then
        echo "Error: could not create '${DIR}/$1'" >&2
        exit 1
    fi
fi
