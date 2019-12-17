#!/bin/bash
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)

timeout=5
mountpoint=/home/pi/hd

sddevlist=`ls /dev/sd*`

check(){
  if [ -f $mountpoint/src/iptalk.py -a -d $mountpoint/mysql ]; then
    mount -o remount,rw /boot
    mount -o remount,rw /
    echo "[INFO] $DATE $TIME HARD DISK CHECK OK" >> /home/pi/reboot.log
    exit 0
  else
    if [ $count -eq $timeout ]; then
      echo "timeout!"
      /home/pi/reboot.sh
    else
      echo -e "check $1 $count ..."
      umount $mountpoint
      mount $1 $mountpoint
      sleep 1
      ((count++))
      check
    fi
  fi
}

for dev in $sddevlist; do
  count=0
  check $dev
done

exit 1
