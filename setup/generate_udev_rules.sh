#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-02
# This script generates the rules file for the udev daemon

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script generates the rules file for the udev daemon"
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
BIN=`echo ${PWD} | sed -re 's/(\/)?setup$//'`

source ${PWD}/../conf/udev_conf.sh

if [[ ! -f ${UDEV_RULES_FILE} ]]; then
    echo "Info '${UDEV_RULES_FILE}' is not a file, creating it."
    touch ${UDEV_RULES_FILE}
    if [[ ! -f ${UDEV_RULES_FILE} ]]; then
        echo "Error. Could not create '${UDEV_RULES_FILE}'" >&2
        exit 1
    fi
fi
if [[ ! -r ${UDEV_RULES_FILE} ]]; then
    echo "Error '${UDEV_RULES_FILE}' is not readable" >&2
    exit 1
fi
if [[ ! -w ${UDEV_RULES_FILE} ]]; then
    echo "Error '${UDEV_RULES_FILE}' is not writtable" >&2
    exit 1
fi
echo "" > ${UDEV_RULES_FILE}
for CHAR in {b..z}; do
    for NUM in {1..9}; do
        echo "ACTION==\"add\",SUBSYSTEM==\"block\",KERNEL==\"sd${CHAR}${NUM}\",ENV{SYSTEMD_WANTS}=\"add-flash@sd${CHAR}${NUM}\"" >> ${UDEV_RULES_FILE}
        echo "ACTION==\"remove\",SUBSYSTEM==\"block\",KERNEL==\"sd${CHAR}${NUM}\",RUN+=\"/home/shmakovpn/flash_autoload/on_remove_flash.sh sd${CHAR}${NUM}\"" >> ${UDEV_RULES_FILE}
        #for ACTION in "add" "remove"; do
        #    echo "ACTION==\"${ACTION}\",SUBSYSTEM==\"block\",KERNEL==\"sd${CHAR}${NUM}\",ENV{SYSTEMD_WANTS}=\"${ACTION}-flash@sd${CHAR}${NUM}\"" >> ${UDEV_RULES_FILE}
        #done
    done
done
# reloading udev rules https://unix.stackexchange.com/questions/39370/how-to-reload-udev-rules-without-reboot/39371
udevadm control --reload-rules && udevadm trigger
echo "DONE"
