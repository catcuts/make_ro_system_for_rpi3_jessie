#!/usr/bin/bash
step=1
#↑ 停留在第几步, 该步之前已经执行完毕
max_step=10

base_dir=`readlink -f $(dirname $0)`

# ____________________________________________________________________________

Black="\033[0;30m"
Dark_Gray="\033[1;30m"
Light_Red="\033[0;31m"
Red="\033[1;31m"
Light_Green="\033[0;32m"
Green="\033[1;32m"
Brown_Orange="\033[0;33m"
Yellow="\033[1;33m"
Light_Blue="\033[0;34m"
Blue="\033[1;34m"
Light_Purple="\033[0;35m"
Purple="\033[1;35m"
Light_Cyan="\033[0;36m"
Cyan="\033[1;36m"
Light_Gray="\033[0;37m"
White="\033[1;37m"
NC='\033[0m' # No Color

# ____________________________________________________________________________

desc_step1(){ echo "停止 IPTALK 和 MYSQL 运行";}
desc_step2(){ echo "重新挂载只读分区为读写";}
desc_step3(){ echo "备份文件到临时目录";}
desc_step4(){ echo "卸载移动硬盘";}
desc_step5(){ echo "挂载第三分区";}
desc_step6(){ echo "复制文件到第三分区";}
desc_step7(){ echo "更新开机启动脚本";}
desc_step8(){ echo "更新分区挂载配置";}
desc_step9(){ echo "更新计划任务";}
desc_step10(){ echo "重启";}

# ____________________________________________________________________________

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
LOGDIR="/home/pi/logs"
_DATE="_$DATE"
_TIME="_$TIME"

# ____________________________________________________________________________

# 每一步执行完毕时调用, 则 step 自增 1 (如: 第 1 步执行完毕, step=2, 即当前位(开始)于第 2 步)
next(){
    last_step=$step
    if [ $step -le $max_step ]; then
        step=$1
        # ((step++))
        sed -i "2s/step=$last_step/step=$step/" $0
        if [ "$sbs" == "yes" ]; then
            echo -ne "[ stage ] 下一步: `desc_step$step` . 继续 ? [y/n] "
            read sbs_cmd
            if [ "$sbs_cmd" != "y" ]; then
                echo "中止 ."
                end 1
            fi
        fi
    fi
}

end(){
    echo -e "${Red}[ W A R N I N G ]${NC} 已退出 . 在关机前，你要手动执行下面这一句${Red}!!${NC}\n\n"\
    "\t${Red}mount -o remount,ro / && mount -o remount,ro /boot${NC}\n"
    if [ $1 -eq 0 ]; then
        echo -e "\033[31m\033[01m\033[05m恭喜你, 圆满完成 .\033[0m"
    fi
    exit $1
}

need_reboot(){
    last_step=$step
    if [ $step -le $max_step ]; then
        ((step++))
    fi
    sed -i "2s/step=$last_step/step=$step/" $0

    echo -ne "${Brown_Orange}[ warn ]${NC} 重启 ? [yes/no] "

    read cmd
    if [ "$cmd" == "yes" ]; then
        reboot
    else
        echo -e "你选择了不重启($cmd 而非 yes) 稍候使用 reboot 来重启 ."
    fi
}

echo -e "当前在第 $step / $max_step 步 ."

# ____________________________________________________________________________

init(){
    # ____________________________________________________________________________

    echo -e "[ info ] 检查分区 ..."

        selected_part=

        mmdevlist=`ls /dev/mmcblk0p* | grep -v /dev/mmcblk0p1 | grep -v /dev/mmcblk0p2`

        for dev in $mmdevlist; do
            fdisk -l $dev
            mmdevsize=`fdisk -l $dev | sed -n "s|Disk $dev: \([^,]*\) GiB, .*|\1|p"`
            mmdevsize=`awk "BEGIN{print $mmdevsize+0 }"`
            echo -ne "上面这个是你的分区吗（大小: $mmdevsize GB） ? [y/n] "
            read confirmed
            if [ "$confirmed" == "y" ]; then
                echo -e "用户选择了分区: $dev"
                selected_part=$dev
            fi
        done 

        if [ -z $selected_part ]; then
            echo -e "${Red}[ erro ]${NC} 没有可用的分区 . 中止 ."
            end 1
        fi

        PARTUUID1=`blkid /dev/mmcblk0p1 | sed 's/.*PARTUUID=\"\(.*\)\"/\1/'`
        PARTUUID2=`blkid /dev/mmcblk0p2 | sed 's/.*PARTUUID=\"\(.*\)\"/\1/'`
    echo -e "[ info ] 检查分区 正常 ."
    
    # ____________________________________________________________________________

    echo -e "[ info ] 检查硬盘 ..."

        selected_hd=

        sddevlist=`ls /dev/sd*`

        for dev in $sddevlist; do
            fdisk -l $dev
            sddevsize=`fdisk -l $dev | sed -n "s|Disk $dev: \([^,]*\) GiB, .*|\1|p"`
            sddevsize=`awk "BEGIN{print $sddevsize+0 }"`
            if [ `echo $sddevsize 900 | awk '{if($1>=$2){printf"ge"}else{printf"lt"}}'` == "ge" ]; then
                echo -ne "上面这个是你的硬盘吗（大小: $sddevsize GB） ? [y/n] "
                read confirmed
                if [ "$confirmed" == "y" ]; then
                    echo -e "用户选择了硬盘: $dev"
                    selected_hd=$dev
                fi
            fi
        done 

        if [ -z $selected_hd ]; then
            echo -e "${Red}[ erro ]${NC} 没有可用的硬盘 . 中止 ."
            end 1
        fi

    echo -e "[ info ] 检查硬盘 正常 ."

    HDUUID=`blkid $selected_hd | sed -n 's/.*UUID=\"\([^"]*\)\".*/\1/p'`
    HDTYPE=`blkid $selected_hd | sed 's/.*TYPE="\([^"]*\)".*/\1/'`

    # ____________________________________________________________________________

    sbs="yes"
    if [ "$1" == "notstepbystep" ]; then
        sbs="no"
    else
        echo -e "[ info ] 已启用: 步步模式(step-by-step mode) ."
    fi

    # ____________________________________________________________________________
}

# ____________________________________________________________________________

# 1. 停止 iptalk 和 mysql 运行
step1(){
    echo -ne "[ info ] 停止 iptalk 和 mysql 运行 ..."
    ps aux | grep iptalk | awk '{print $2}' | xargs kill -9 && service mysql stop
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 2. 重新挂载只读分区为读写
step2(){
    echo -ne "[ info ] 停止 iptalk 和 mysql 运行 ..."
    mount -o remount,rw / && mount -o remount,rw /boot
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 3. 备份文件到临时目录
step3(){
    echo -ne "[ info ] 备份文件到临时目录 ..."
    mkdir /hyt && cp -rp /home/pi/hd/* /hyt/
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 4. 卸载移动硬盘
step4(){
    echo -ne "[ info ] 卸载移动硬盘 ..."
    umount -l /home/pi/hd
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 5. 挂载第三分区
step5(){
    echo -ne "[ info ] 挂载第三分区 ..."
    mount $selected_part /home/pi/hd
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 6. 复制文件到第三分区
step6(){
    echo -ne "[ info ] 复制文件到第三分区 ..."
    cp -rp /hyt/* /home/pi/hd/
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 7. 更新开机启动脚本
step7(){
    echo -ne "[ info ] 更新开机启动脚本 ..."
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

mount -o remount,rw /

{  # your 'try' block
    echo "Asynchronizing time ..." && \
        hwclock -s && \
    echo "Time asynchronized ."
} || {  # your 'catch' block
    echo 'E R R O R - A S Y N C - T I M E'
}

mount -o remount,ro /

{  # your 'try' block
    bash /home/pi/mount_hd.sh && \
    bash /home/pi/link_crontabs.sh && \
    bash /home/pi/start_iptalk_on_rpi3.sh &
} || {  # your 'catch' block
    echo 'E R R O R - R U N N I N G - I P T A L K'
}

exit 0
EOF
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 8. 更新分区挂载配置
step8(){
    echo -ne "[ info ] 更新分区挂载配置 ..."
# EOF 不加双引号可以在内容中使用本脚本变量
cat << EOF > /etc/fstab
proc            /proc           proc    defaults             0       0
/dev/mmcblk0p1  /boot           vfat    defaults,ro          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime,ro  0       1
$selected_part  /home/pi/hd     ext4    defaults,noatime     0       0
# a swapfile is not a swap partition, no line here
#   use  dphys-swapfile swap[on|off]  for that

UUID=$HDUUID /home/pi/hd/src/data/ftp $HDTYPE defaults,nofail 0 1

# For Debian Jessie
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
tmpfs           /var/log        tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0
EOF
    echo -e "好了 ."
}

# ____________________________________________________________________________

# 9. 更新计划任务
step9(){
    echo -ne "[ info ] 更新计划任务 ..."
    touch /home/pi/log_hd.sh
cat << "EOF" > /home/pi/log_hd.sh
#!/bin/bash
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)

mountpoint=/home/pi/hd/src/data/ftp

echo "[INFO] $DATE $TIME YOU STILL ALIVE !" >> $mountpoint/hd.log
EOF
    chmod 777 /home/pi/log_hd.sh

    # write out current crontab
    crontab -l > newcron
    # 清除所有遗留定时任务
    sed -i 's/^[^#].*//g' newcron
    # echo new cron into cron file
    echo "*/1 * * * *  /home/pi/log_hd.sh" >> newcron
    echo "0 0 */2 * *  /home/pi/sweep_old_iptalk_database_bkups.sh" >> newcron
    echo "0 */1 * * *  /home/pi/backup_iptalk_database.sh" >> newcron
    # install new cron file
    crontab newcron
    rm newcron

    echo "好了 ."
}

# ____________________________________________________________________________

step10(){
    need_reboot
}

# ____________________________________________________________________________

init

for k in $( seq $step $max_step )
do
    echo -e "----------- ----------- -----------"
    next $k
    echo -e "\n----------- 第 $step / $max_step 步 -----------"
    step$k
done

end 0

# ____________________________________________________________________________
