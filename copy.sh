if [ -f $3 ]; then
    START=`date +%s%N`;
    echo -ne "复制 ..."
    sd1=`df -h | grep $2 | grep "boot" | awk '{print$6}'`
    sd2=`df -h | grep $2 | grep -v "boot" | awk '{print$6}'`
    dest=$sd2/home/pi/make_ro_system_for_rpi3_jessie
    rm -rf $dest
    unzip -q $3 -d $dest
    #cp -r $3 `df -h | grep $2 | grep -v "boot" | awk '{print$6}'`/home/pi/

    MID=`date +%s%N`
    midtime=$((MID-START))
    midtime=`echo "$midtime" | awk '{printf ("%.2f\n", $midtime/1000000000)}'`

    echo -e "好了 . 花费: $midtime 秒 ."

    echo -ne "卸载 ..."
    umount $sd1 $sd2

    END=`date +%s%N`
    endtime=$((END-START))
    endtime=`echo "$endtime" | awk '{printf ("%.2f\n", $endtime/1000000000)}'`
    #time=`expr $time / 1000000`

    echo -e "好了 . 花费: $endtime 秒 ."
fi
