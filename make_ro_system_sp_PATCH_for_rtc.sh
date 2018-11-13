

# ____________________________________________________________________________
step7(){ # reentrant
echo -ne "[ info ] 添加启动项 ..."
cat << "EOF" > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi

{  # your 'try' block
    echo "Asynchronizing time ..." && \
        mount -o remount,rw / && \
        #echo "ds1307 0x68" > /sys/class/i2c-adapter/i2c-1/new_device && \
        #sleep 1  # wait for several time for /dev/rtc to be created && \
        hwclock -s && \
        mount -o remount,ro / && \
    echo "Time asynchronized ."
} || {  # your 'catch' block
    echo 'E R R O R - A S Y N C - T I M E'
}

{  # your 'try' block
    bash /home/pi/check_hd.sh && \
    bash /home/pi/hd/link_crontabs.sh && \
    bash /home/pi/start_iptalk_on_rpi3.sh &
} || {  # your 'catch' block
    echo 'E R R O R - R U N N I N G - I P T A L K'
}

exit 0
EOF
echo -e "好了 ."
}

# ____________________________________________________________________________
# winux
step19(){
    echo -ne "[ stage ] 是否启用 RTC ? [y/n] "

    read cmd
    if [ "$cmd" == "y" ]; then
        if [ "`tail -1 /boot/config.txt | grep ^dtoverlay`" == "" ]; then
            echo -e "\ndtoverlay=i2c-rtc,ds1307" >> /boot/config.txt
        fi
        echo -e "RTC 已启用为: dtoverlay=i2c-rtc,ds1307 ."
    else
        echo -e "你选择了不启用($cmd 而非 y) 跳过 ."
    fi
}

# ____________________________________________________________________________

step7
step19