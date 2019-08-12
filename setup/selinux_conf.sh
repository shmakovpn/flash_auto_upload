#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-12

# This script configures Selinux for rsync

# this sets needed context to my /files folder
sudo semanage fcontext -a -t rsync_data_t '/files(/.*)?'
sudo restorecon -Rv '/files'
# sets needed booleans
sudo setsebool -P rsync_client 1
