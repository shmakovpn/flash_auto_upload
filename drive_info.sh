#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-07
# This script show informantion about a removable media
# Using: '$0 disk_name'
# example '$0 sdb1'

# begin command line arguments
MORE_HELP_STR="Use '$0 -h' for more help."
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then 
        echo "This script shows infornamtion of a removable disk"
        echo "Use '$0 [-h] disk_name'"
        echo "    disk_name the name of the mounted removable drive (like sdb1, sdc1, ...)"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    echo "Error. A first command line argument is not presented. ${MORE_HELP_STR}"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$ ]]; then
    echo "Error. A first command line argument '$1' is not a valid disk name. ${MORE_HELP_STR}"
    exit 1
fi
# end command line arguments

sudo ls -al /dev | grep $1
sudo mount -l | grep $1
sudo ls -al /media/flash | grep $1

