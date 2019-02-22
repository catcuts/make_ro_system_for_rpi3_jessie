mount -o remount,rw / && \
rm -rf /var/spool/cron/crontabs && \
ln -s /home/pi/hd/crontabs /var/spool/cron/crontabs
mount -o remount,ro / && \