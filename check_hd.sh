
timeout=5
mountpoint=/home/pi/hd

sddevlist=`ls /dev/sd*`

check(){
  if [ -f $mountpoint/src/iptalk.py ]; then
    echo "ok: $1"
    exit 0
  else
    if [ $count -eq $timeout ]; then
      echo "timeout!"
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
