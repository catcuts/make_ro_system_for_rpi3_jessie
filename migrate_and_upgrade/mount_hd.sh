#!/bin/bash

mountpoint=/home/pi/hd/src/data/ftp

sddevlist=`ls /dev/sd*`

_mount(){
  echo -n "mounting $1 ..." && \
  {
    umount -l $1
  } || {
    echo 'cannot umount $1'
  }
  {  # your 'try' block
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
