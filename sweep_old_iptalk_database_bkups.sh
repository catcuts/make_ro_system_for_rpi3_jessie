#!/bin/bash

find /home/pi/hd/iptalk_database_bkups/ -mtime +2 -type f | xargs rm -rf
