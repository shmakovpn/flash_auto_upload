#!/bin/bash
sudo ls -al /dev | grep $1
sudo mount -l | grep $1
sudo ls -al /media/flash | grep $1
