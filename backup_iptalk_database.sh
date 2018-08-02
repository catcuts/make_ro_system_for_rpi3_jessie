#!/bin/bash

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
_DATE="_$DATE"
_TIME="_$TIME"

mysqldump -uroot -proot iptalk > /home/pi/hd/iptalk_database_bkups/iptalk_bkup$_DATE$_TIME.sql
