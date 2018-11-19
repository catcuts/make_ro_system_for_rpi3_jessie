date

echo -ne '时间正确与否？[y/n] '

read confirm

if [ "$confirm" != "y" ]; then
  #echo $confirm
  hwclock -r -D
else
  if [ "`mount | grep ^/dev/mm | grep rw`" == "" ]; then echo ok; fi
fi

