#!/bin/bash
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
_TIME="_$TIME"

sudo ps aux | grep iptalk | awk '{print$2}' | xargs kill -9
sudo ps aux | grep test | awk '{print$2}' | xargs kill -9

mount -o remount,rw /boot
mount -o remount,rw /
echo "[INFO] $DATE $TIME SYSTEM REBOOT" >> /home/pi/reboot.log

sudo /sbin/reboot
