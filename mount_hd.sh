#!/bin/bash

mountpoint=/home/pi/hd/src/data/ftp

sddevlist=`ls /dev/sd*`

_mount(){
  {  # your 'try' block
    echo -n "mounting $1 ..." && \
    umount -l $1 && \
    mount $1 $mountpoint && \
    echo 'ok'
    exit 0
  } || {  # your 'catch' block
    echo "cannot mount $1"
  }
}

for dev in $sddevlist; do
  _mount $dev
done
