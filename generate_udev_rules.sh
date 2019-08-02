#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-02
# This script generates the rules file to the udev daemon
FILE="/etc/udev/rules.d/10-onflash.rules"
if [[ ! -f $FILE ]]; then
    echo "Error '$FILE' is not a file" >&2
    exit 1
fi
if [[ ! -r $FILE ]]; then
    echo "Error '$FILE' is not readable" >&2
    exit 1
fi
if [[ ! -w $FILE ]]; then
    echo "Error '$FILE' is not writtable" >&2
    exit 1
fi
echo "" > $FILE
for CHAR in {b..z}; do
    for NUM in {1..9}; do
        for ACTION in "add" "remove"; do
            echo "ACTION==\"${ACTION}\",SUBSYSTEM==\"block\",KERNEL==\"sd${CHAR}${NUM}\",RUN+=\"/home/shmakovpn/on_${ACTION}_flash.sh sd${CHAR}${NUM}\"" >> $FILE
        done
    done
done
# reloading udev rules https://unix.stackexchange.com/questions/39370/how-to-reload-udev-rules-without-reboot/39371
udevadm control --reload-rules && udevadm trigger
echo "DONE"
