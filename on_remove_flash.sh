#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-02
# This script processes the disk removing event

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script processes the disk removing event"
        echo "Use '$0 [-h] disk_name'"
        echo "    disk_name the name of mounted removable drive (like sdb1, sdc1, ..)"
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

logger -sp local0.info "'$0' flash device '$1' removed 0161392a-b4d1-11e9-ba84-080027858e30"

if [[ -b /dev/$1 ]]; then
    logger -sp local0.err "'$0' Error: device '/dev/$1' still exists 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi

# killal copy_files.sh processes for the drive
PS_LIST=`/bin/ps aux | grep copy_files.sh | grep $1 | grep -v grep | sed -re 's/[^ ]*[ ]*([^ ]*)[ ]*.*/\1/' | sort -u`
PS_ARR=(${PS_LIST//\n/ })
for ps in "${PS_ARR[@]}"; do
    KILL_STATUS=`kill -9 ${ps} 2>&1`
    if [[ $? -eq 0 ]]; then
        logger -sp local0.info "'$0'. Process '${ps} copy_files.sh $1' killed. 0161392a-b4d1-11e9-ba84-080027858e30"
    else
        logger -sp local0.err "'$0'. Could not kill process ${ps} copy_files.sh $1: ${KILL_STATUS} 0161392a-b4d1-11e9-ba84-080027858e30"
    fi
done

PS_LIST=`/usr/sbin/lsof | grep "${MOUNT_DIR}/$1" | sed -re 's/[^ ]*[ ]*([^ ]*)[ ]*.*/\1/' | sort -u`
PS_ARR=(${PS_LIST//\n/ })
for ps in "${PS_ARR[@]}"; do
    KILL_STATUS=`kill -9 ${ps} 2>&1`
    if [[ $? -eq 0 ]]; then
        logger -sp local0.info "'$0'. Process ${ps} killed. 0161392a-b4d1-11e9-ba84-080027858e30"
    else
        logger -sp local0.err "'$0'. Could not kill process ${ps} $1: ${KILL_STATUS} 0161392a-b4d1-11e9-ba84-080027858e30"
    fi
done

mount -l | grep -Pi "${MOUNT_DIR}/$1"
if [[ $? -eq 0 ]]; then
    logger -sp local0.warning "'$0' Warning: direcory '${MOUNT_DIR}/$1' is still mounted. Unmounting. 0161392a-b4d1-11e9-ba84-080027858e30"
    umount ${MOUNT_DIR}/$1
    mount -l | grep -Pi "${MOUNT_DIR}/$1"
    if [[ $? -eq 0 ]]; then
        logger -sp local0.err "'$0' Error: could not unmount directory '${MOUNT_DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
else
    logger -sp local0.info "'$0'. directory '${MOUNT_DIR}/$1' not mounted. 0161392a-b4d1-11e9-ba84-080027858e30"
fi

if [[ ! -d ${MOUNT_DIR} ]]; then
    mkdir -p ${MOUNT_DIR}
    if [[ ! -d ${MOUNT_DIR} ]]; then
        logger -sp local0.err "'$0' Error: could not create '${MOUNT_DIR}' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    else 
        logger -sp local0.warning "'$0'. Created directory ${MOUNT_DIR}. 0161392a-b4d1-11e9-ba84-080027858e30"
    fi
fi
if [[ -d ${MOUNT_DIR}/$1 ]]; then
    rmdir ${MOUNT_DIR}/$1
    if [[ -d ${MOUNT_DIR}/$1 ]]; then
        logger -sp local0.err "'$0' Error: could not remove '${MOUNT_DIR}/$1' 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    else 
        logger -sp local0.info "'$0'. Directory '${MOUNT_DIR}/$1' removed. 0161392a-b4d1-11e9-ba84-080027858e30"
    fi
else
    logger -sp local0.info "'$0'. Directory '${MOUNT_DIR}/$1' does not exist. 0161392a-b4d1-11e9-ba84-080027858e30"
fi


