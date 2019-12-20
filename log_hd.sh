#!/bin/bash
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)

mountpoint=/home/pi/hd/src/data/ftp

echo "[INFO] $DATE $TIME YOU STILL ALIVE" >> $mountpoint/hd.log
