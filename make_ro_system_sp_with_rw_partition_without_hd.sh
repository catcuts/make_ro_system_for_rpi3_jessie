#!/usr/bin/bash
step=1
#↑ 停留在第几步, 该步之前已经执行完毕
max_step=20

base_dir=`readlink -f $(dirname $0)`

srcs=`ls -l | grep "^d.*src" | awk '{print $9}'`

no_network=1

retain_mysql_data=0

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

desc_step1(){ echo "停止 iptalk 和 备份 iptalk 数据库 然后停止 mysql";}
desc_step2(){ echo "备份 mysql 数据 和 iptalk 资源";}
desc_step3(){ echo "创建新的读写分区";}
desc_step4(){ echo "挂载新的读写分区，移动 mysql 数据 和 iptalk 资源 到 此分区";}
desc_step5(){ echo "配置 mysql 运行参数";}
desc_step6(){ echo "设置 定时清理 和 定时备份 任务";}
desc_step7(){ echo "配置 iptalk 进程为启动项";}
desc_step8(){
    if [ "$precondition" == "winux" ]; then echo -e "导入数据库"; fi
    if [ "$precondition" == "local" ]; then echo -e "安装依赖"; fi
}
desc_step9(){ echo "试运行";}
desc_step10(){ echo "修改 /boot/cmdline.txt 和 /etc/fstab";}
desc_step11(){ echo "移除无关软件与服务";}
desc_step12(){ echo "用 busybox 替代默认日志管理器";}
desc_step13(){ echo "停用关于 交换分区 和 文件系统 的检查, 并设置为 只读";}
desc_step14(){ echo "移动部分系统文件到临时文件系统";}
desc_step15(){ echo "移动部分锁定文件到临时文件系统";}
desc_step16(){ echo "修改 /etc/cron.hourly/fake-hwclock";}
desc_step17(){ echo "移除部分启动脚本";}
desc_step18(){ echo "设置 dhcpcd 服务超时(20s)";}
desc_step19(){ echo "Real Time Clock 启用确认";}
desc_step20(){ echo "重启确认";}

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
    echo -e "${Red}[ W A R N I N G]${NC} 已退出 . 在关机前，你要手动执行下面这一句${Red}!!${NC}\n\n"\
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

check_params(){
    if [ `echo $1 $max_step | awk '{if($1>=$2 || $1<=0){printf"sb"}else{printf"ok"}}'` == "sb" ]; then
        echo -e "${Red}[ erro ]${NC} 步数越界! 中止 ."
        end 1
    else
        echo 很正常啊
    fi
}

# ____________________________________________________________________________

precondition="local"
if [ -n "$1" ]; then 
    if [[ "$1" == "windows" || "$1" == "linux" ]]; then
        precondition="winux"
        if [ -n "$2" ]; then
            check_params $2 
            step=$2
            sed -i "2s/step=.*/step=$step/" $0
        fi
    else
        check_params $1
        step=$1
        sed -i "2s/step=.*/step=$step/" $0
    fi
fi

echo -e "当前在第 $step / $max_step 步 . 前提: $precondition ."

# ____________________________________________________________________________

init(){
    if [ "$precondition" == "local" ]; then

        if [ $no_network != 0 ]; then

            echo -ne "[ info ] 检查网络 ..."

                ret_code=`curl -I -s --connect-timeout 5 www.baidu.com -w %{http_code} | tail -n1`
                # ret_code maybe none so insert an x
                if [ "$ret_code" != "200" ]; then
                    echo -e "\n${Red}[ erro ]${NC} 检查网络 异常 . 中止 ."
                    end 1
                fi

            echo -e "正常 ."
        
        fi
        
    # ____________________________________________________________________________

        echo -ne "[ info ] 确认以下步骤:\n \
    1. SD 卡扩容\n \
    2. bash reboot.sh\n \
        已按顺序完成 ? [yes/no] "
        read done_prepare
        if [ "$done_prepare" != "yes" ]; then
            echo -e "你选择了未完成($done_prepare 而非 yes) . 中止 . 确认完成以上步骤后再重试 ."
            end 1
        fi
    fi

    # ____________________________________________________________________________

    # echo -e "[ info ] 检查硬盘 ..."

    #     selected_hd=

    #     sddevlist=`ls /dev/sd*`

    #     for dev in $sddevlist; do
    #         fdisk -l $dev
    #         sddevsize=`fdisk -l $dev | sed -n "s|Disk $dev: \([^,]*\) GiB, .*|\1|p"`
    #         sddevsize=`awk "BEGIN{print $sddevsize+0 }"`
    #         if [ `echo $sddevsize 900 | awk '{if($1>=$2){printf"ge"}else{printf"lt"}}'` == "ge" ]; then
    #             echo -ne "上面这个是你的硬盘吗（大小: $sddevsize GB） ? [y/n] "
    #             read confirmed
    #             if [ "$confirmed" == "y" ]; then
    #                 echo -e "用户选择了硬盘: $dev"
    #                 selected_hd=$dev
    #             fi
    #         fi
    #     done 

    #     if [ -z $selected_hd ]; then
    #         echo -e "${Red}[ erro ]${NC} 没有可用的硬盘 . 中止 ."
    #         end 1
    #     fi

    # echo -e "[ info ] 检查硬盘 正常 ."

    # ____________________________________________________________________________

    # echo -ne "[ info ] 复制核心文件到 /home/pi ..."

    #     for file in check_hd.sh link_crontabs.sh start_iptalk_on_rpi3.sh sweep_old_iptalk_database_bkups.sh backup_iptalk_database.sh; do
    #         cp -p $base_dir/$file /home/pi
    #         chmod +x /home/pi/$file
    #     done

    # echo -e "完毕 ."

    # ____________________________________________________________________________

    sbs="yes"
    if [ "$1" == "notstepbystep" ]; then
        sbs="no"
    else
        echo -e "[ info ] 已启用: 步步模式(step-by-step mode) ."
    fi

    PARTUUID1=`blkid /dev/mmcblk0p1 | sed 's/.*PARTUUID=\"\(.*\)\"/\1/'`
    PARTUUID2=`blkid /dev/mmcblk0p2 | sed 's/.*PARTUUID=\"\(.*\)\"/\1/'`
    # HDUUID=`blkid $selected_hd | sed -n 's/.*UUID=\"\([^"]*\)\".*/\1/p'`
    # HDTYPE=`blkid $selected_hd | sed 's/.*TYPE="\([^"]*\)".*/\1/'`
}
# ____________________________________________________________________________
# winux
step1(){ # reentrant
    echo -ne "${Brown_Orange}[ warn ]${NC} 是否允许停止 iptalk / web 端 ? [yes/no] "

        read allow_stop_iptalk
        if [ "$allow_stop_iptalk" != "yes" ]; then
            echo -e "你选择了不允许($allow_stop_iptalk 而非 yes) . 中止 . 确认可以停止后再试 ."
            end 1
        fi

    echo -ne "[ info ] 停止 iptalk 进程 ..."

        ps aux | grep "iptalk" | awk '{print$2}' | xargs kill -9
        ps aux | grep "test" | awk '{print$2}' | xargs kill -9

    echo -e "完毕 ."

    echo -ne "[ info ] 导出 iptalk 数据库 ..."

        iptalksql=/home/pi/iptalk_bkup$_DATE$_TIME.sql

        mysqldump -uroot -proot iptalk > $iptalksql

        iptalksqlsize=`ls -l $iptalksql | awk '{print$5}'`

        if [ "$iptalksqlsize" == "0" ]; then
            echo -ne "\n${Red}[ erro ]${NC} 导出 iptalk 数据库 失败 . 继续 ? [y/n] "
            read _continue
            if [ "$_continue" != "y" ]; then
                end 1
            else
                echo "完毕 ."
            fi
        fi

    echo -ne "[ info ] 停止 mysql 服务 ..."
        
        if [ "$precondition" == "winux" ]; then
            ps aux | grep mysql | awk '{print$2}' | xargs kill -TERM
        else
            /etc/init.d/mysql stop > /dev/null
        fi

    echo -e "完毕 ."
}

# ____________________________________________________________________________

backup(){
    if [ -d $1_bkup ]; then
        echo -e "[ info ] 备份数据已存在 ."
        # if [ -d $1 ]; then
        #     echo -e "${Brown_Orange}[ warn ]${NC} 备份数据($1_bkup)已存在: "
        #     ls -l $1_bkup
        #     echo -ne "\t删除 ? [yes/no] "
        #     read delete
        #     if [ "$delete" != "yes" ]; then
        #         echo -e "你选择了保留($delete 而非 yes) ."
        #     else
        #         echo -ne "你选择了删除. 删除中 ..."
        #         rm -rf $1_bkup
        #         echo "好了 ."  
        #         echo -ne "[ info ] 备份 $1 到 $1_bkup ..."
        #         cp -r -p $1 $1_bkup
        #         echo -e "好了 ."
        #     fi
        # else
        #     echo -e "[ info ] 备份数据已存在 ."
        # fi
    else
        echo -ne "[ info ] 备份 $1 到 $1_bkup ..."
        copy $1 $1_bkup
        echo -e "好了 ."
    fi
}

check(){
    du -h --max-depth=1 $1_bkup
    if [ -d $1 ]; then
        echo -e "对应源文件为: "
        du -h --max-depth=1 $1
        echo -ne "确认备份无误 ? [yes/no] "
        read checked
        if [ "$checked" == "no" ]; then
            echo -e "你认为备份有误($checked 而非 yes) . 中止 . 检查备份文件后再试 ."
            end 1
        fi

        if [ "$checked" == "yes" ]; then
            echo -ne "你认为备份无误($checked 而非 no) . 删除源文件 ..."
            rm -rf $1
            echo -e "好了 ."
        else
            echo -e "${Red}[ erro ]${NC} 用户模棱两可($checked 而非 yes/no). 中止 . 下定决心后再试 ."
        fi
    else
        echo -e "对应源文件已删除 . 应该是上一次确认过了 ."
    fi
}
# winux
step2(){ # reentrant
    echo -e "[ info ] 备份 mysql 数据 ..."

        backup /var/lib/mysql

    echo -e "[ info ] 备份 mysql 数据 完毕 . \n\033[31m\033[01m\033[05m[ 重要 ! ]\033[0m 检查备份: "
        
        check /var/lib/mysql

    echo -e "[ info ] 备份 iptalk 资源 ..."

        backup /home/pi/src

    echo -e "[ info ] 备份 iptalk 资源 完毕 . \n\033[31m\033[01m\033[05m[ 重要 ! ]\033[0m 检查备份: "
        
        check /home/pi/src
}

# ____________________________________________________________________________
# winux
step3(){
    echo -e "${Brown_Orange}[ warn ]${NC} 当前系统分区表如下: "
        fdisk -l
    echo -ne "\t确定继续 ? [yes/no] "
        read confirmed
        if [ "$confirmed" != "yes" ]; then
            echo -e "${Red}[ erro ]${NC} 你选择了取消继续($confirmed 而非 yes) . 中止 . 确认后再试 ."
            exit 1
        fi

    echo -e "[ info ] 创建新分区 ..."
        firstp2=$((1+`fdisk -l /dev/mmcblk0 | grep /dev/mmcblk0p1 | awk '{print$3}'`))
        firstp3=$(($firstp2+7549747+1))
        (
        echo p # show current partition table
        echo d # delete partition
        echo 2 # the second partition
        echo n # add a new partition
        echo p # primary partition
        echo 2 # partition number
        echo $firstp2 # first sector
        echo +7549747 # last sector
        echo p # show current partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 3 # Partition number 
        echo $firstp3  # First sector 
        echo   # Last sector 
        echo p # show updated partition table
        echo w # Write changes
        ) | fdisk /dev/mmcblk0
    echo -e "[ info ] 创建新分区 完毕 ."

    echo -e "[ info ] 格式化新分区 ..."
        partx -a /dev/mmcblk0
        mkfs -t ext4 /dev/mmcblk0p3
    echo -e "[ info ] 格式化新分区 完毕 ."

    need_reboot

    exit 0
}

# ____________________________________________________________________________

copy(){
    if [ "`ls $2`" != "" ]; then
        echo -e "${Brown_Orange}[ warn ]${NC} 数据($2)已存在: "
        ls -l $2
        echo -ne "\t删除 ? [yes/no] "
        read delete
        if [ "$delete" != "yes" ]; then
            echo -e "你选择了保留($delete 而非 yes) ."
        else
            echo -ne "你选择了删除. 删除中 ..."
            # 注意不要 rf -rf $2/* 因为这对软连接无效
            rm -rf $2
            mkdir -p $2
            echo "好了 . "
            echo -ne "复制 $1 到 $2 ..."
            cp -r -p $1/* $2/
            echo "好了"
        fi
    else
        echo -ne "复制 $1 到 $2 ..."
        cp -r -p $1/* $2/
        echo "好了"
    fi

    if [ "$3" == "mysql" ]; then
        eval "retain_$3_data=1"
    fi
}
# winux
step4(){
    
    resize2fs /dev/mmcblk0p2

    check_partition

    mounted=`df -h | grep /dev/mmcblk0p3 | awk '{print$6}'`

    if [ -n "$mounted" ]; then
        echo -ne "[ info ] 卸载分区 ..."
        umount $mounted
        mounted=`df -h | grep /dev/mmcblk0p3 | awk '{print$6}'`
        if [ -n "$mounted" ]; then
            echo -e "\n${Red}[ erro ]${NC} 卸载分区失败. 中止 . 手动卸载后重试 ."
            exit 1
        else
            echo -e "好了 ."
        fi
    fi

    if [ "$P3TYPE" != "ext4" ]; then
        echo -e "${Red}[ erro ]${NC} 分区不是 ext4 格式. 中止 . 自行格式化后重试 ."
        exit 1
    fi

    # ________________________________________________________________________

    echo -ne "[ info ] 挂载 /dev/mmcblk0p3 到 /var_temp (新分区挂载点) ..."
        # /var_temp 只是一个临时的挂载点，重启后 /dev/mmcblk0p3 将被挂载到 /var （见 step10 修改 /etc/fstab）
        # 在重启之前，对 /var_temp 的读写等同于对 /dev/mmcblk0p3 的读写
        # 在重启之后，对 /var 的读写等同于对 /dev/mmcblk0p3 的读写
        # TODO：试下先备份 /var 再直接挂载到 /var，免去 /var_temp
        #       否则在 step4 之后如果发生重启，就没有 /var_temp 了
        if [ ! -d /var_temp ]; then
            mkdir -p /var_temp
        fi
        mount /dev/mmcblk0p3 /var_temp
        mounted=`df -h | grep /dev/mmcblk0p3 | awk '{print$6}'`
        if [ "$mounted" != "/var_temp" ]; then
            echo -e "\n${Red}[ erro ]${NC} 挂载分区失败. 中止 . 检查后重试 ."
            exit 1
        else
            echo -e "好了 ."
        fi

    # ________________________________________________________________________

    mkdir /var_bkup /home_bkup /srv_bkup
    echo -ne "[ info ] 备份 /var/* 到 /var_bkup ..."
        cp -r -p /var/* /var_bkup/
    echo "好了 ."
    check /var /var_bkup

    echo -ne "[ info ] 备份 /home/* 到 /home_bkup ..."
        cp -r -p /home/* /home_bkup/
        #cp -r -p /srv/* /srv_bkup/
    echo "好了 ."
    check /home /home_bkup

    # ________________________________________________________________________

    echo -ne "[ info ] 移动 /var/* 到 /var_temp ... "
        cp -r -p /var/* /var_temp/
    echo "好了 ."
    check /var /var_temp

    # ________________________________________________________________________

    echo -ne "[ info ] 创建一些必要的文件夹 ..."
        mkdir -p /hyt \
        /var/local/home \
        /var/local/srv \
        /var/local/hyt \
        /var_temp/local/home \
        /var_temp/local/srv \
        /var_temp/local/hyt
    echo "好了 ."

    echo -ne "[ info ] 移动 /home/* 到 /var_temp/local/home ..."
        cp -r -p /home/* /var_temp/local/home
        #cp -r -p /srv/* /var_temp/local/srv
    echo "好了 ."    
    check /home /var_temp/local/home

    # ________________________________________________________________________

    echo -e "[ info ] 复制 mysql 数据 ..."
        copy /var/lib/mysql_bkup /var_temp/local/hyt/mysql mysql
        chown -R mysql:mysql /var_temp/local/hyt/mysql
    echo -e "[ info ] 复制 mysql 数据 完毕 ."

    echo -e "[ info ] 复制 iptalk 资源 ..."

        echo "[ info ] 选择 iptalk 资源版本："
        select src in $srcs;
        do
            break
        done

        echo "[ info ] 你选择了：$src ."

        # echo "[ info ] 选择 iptalk 资源版本："
        # select version in $src"（美一版）" $src"_neutral（中性版）";
        # do
        #     break
        # done

        # echo "[ info ] 你选择了：$version ."

        # if [ $version == $src"（美一版）" ]; then
        #     src=$src
        # elif [ $version == $src"_neutral（中性版）" ]; then
        #     src="$src"_neutral
        # fi

        if [ -d $base_dir/$src ]; then
            copy $base_dir/$src /var_temp/local/hyt/iptalk/src
        elif [ -d $base_dir/src ]; then
            echo -e "${Red}[ error ]${NC} 没找到 $version ."
            echo -e "${Red}[ info ]${NC} 选择了 src . 不过要注意 >0.5.7 的版本才支持只读系统 ."
            copy $base_dir/src /var_temp/local/hyt/iptalk/src
        else
            echo -e "${Red}[ error ]${NC} 没找到 $version 和 src ."
            echo -e "${Red}[ info ]${NC} 选择了 src_bkup . 不过要注意 >0.5.7 的版本才支持只读系统 ."
            copy /home/pi/src_bkup /var_temp/local/hyt/iptalk/src
        fi
    echo -e "[ info ] 复制 iptalk 资源 完毕 ."

    echo -e "[ info ] 检查: "
        ls -l /var_temp/local/hyt/mysql /var_temp/local/hyt/iptalk/src
    echo -ne "[ info ] 是否正确 ? [y/n] "
        read checked
        if [ "$checked" != "y" ]; then
            echo -e "${Red}[ erro ]${NC} 用户检查到错误, 中止 ."
            end 1
        fi
}

# ____________________________________________________________________________

step5(){ # reentrant
    echo -ne "[ info ] 配置 mysql 运行参数 ..."

        mv /etc/mysql/my.cnf /etc/mysql/my.cnf.bkup$_DATE$_TIME

        cp -p $base_dir/my.cnf.out /etc/mysql/my.cnf

        chmod 0444 /etc/mysql/my.cnf

    echo "好了 ."
}

# ____________________________________________________________________________
# winux
step6(){ # reentrant
    echo -ne "[ info ] 设置定时任务 ..."
        # write out current crontab
        crontab -l > newcron
        # 清除所有遗留定时任务
        sed -i 's/^[^#].*//g' newcron
        # echo new cron into cron file
        # echo "0 */1 * * *  /home/pi/check_hd_reboot.sh" >> newcron
        echo "0 0 */2 * *  /home/pi/sweep_old_iptalk_database_bkups.sh" >> newcron
        echo "0 */1 * * *  /home/pi/backup_iptalk_database.sh" >> newcron
        # install new cron file
        crontab newcron
        rm newcron
    echo "好了 ."
}

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
    bash /var/local/hyt/iptalk/check_hd.sh && \
    bash /var/local/hyt/iptalk/start_iptalk_on_rpi3.sh &
} || {  # your 'catch' block
    echo 'E R R O R - R U N N I N G - I P T A L K'
}

exit 0
EOF
echo -e "好了 ."
}

# ____________________________________________________________________________
# winux
step8(){ # reentrant
    if [ "$precondition" == "winux" ]; then
        if [ "$retain_mysql_data" == 0 ]; then
            bash start_iptalk_on_rpi3.sh only-mysql

            echo -e "[ info ] 删除原数据库 ..."
                mysql -uroot -proot -e 'drop database iptalk'
            echo -e "[ info ] 删除原数据库 完毕 ."

            iptalksql=$base_dir/iptalk_bkup_before_ro.sql

            iptalksqlsize=`ls -l $iptalksql | awk '{print$5}'`

            if [ "$iptalksqlsize" == "0" -o "$iptalksqlsize" == "" ]; then
                echo -e "${Brown_Orange}[ warn ]${NC} 没有原数据库可以导入 ."
            else
                echo -e "[ info ] 导入原数据库 ..."
                    mysql -uroot -proot iptalk < $iptalksql
                echo -e "[ info ] 导入原数据库 完毕 ."
            fi
        else 
            echo -e "已选择保留数据库 ."
        fi
    else    
        echo -e "安装依赖 ..."
            pip install pycrypto*
        echo -e "安装依赖 完毕 ."
    fi
}

# ____________________________________________________________________________
# winux
step9(){ # reentrant
    echo -e "试运行 ..."
    bash /etc/rc.local
    echo -ne "试运行 确认成功 ? [y/n] "
    read successed
    if [ "$successed" != "y" ]; then
        echo -e "${Red}[ erro ]${NC} 用户确认试运行失败, 中止 ."
        end 1
    fi
}

# ____________________________________________________________________________
# winux
step10(){
    echo -e "[ info ] 修改 /boot/cmdline.txt ..."

        # original: PARTUUID=992231d4-02 instead of /dev/mmcblk0p2 
        sed -i "s/PARTUUID=$PARTUUID2/\/dev\/mmcblk0p2/" /boot/cmdline.txt

    echo -e "[ info ] 修改 /boot/cmdline.txt 完毕 ."

    echo -e "[ info ] 修改 /etc/fstab ..."

cat << EOF > /etc/fstab
proc            /proc           proc    defaults             0       0
/dev/mmcblk0p1  /boot           vfat    defaults             0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime     0       1
/dev/mmcblk0p3  /var            ext4    defaults,noatime     0       0
/var/local/home /home           none    defaults,bind        0       0
/var/local/srv  /srv            none    defaults,bind        0       0
/var/local/hyt  /hyt            none    defaults,bind        0       0

# For Debian Jessie
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
tmpfs           /var/log        tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0
EOF

    #     sed -i "s/\(PARTUUID=$PARTUUID1.*defaults\)\(\s*.*\)/\1,ro\2/" /etc/fstab

    #     sed -i "s/\(PARTUUID=$PARTUUID2.*defaults,noatime\)\(\s*.*\)/\1,ro\2/" /etc/fstab

    #     # original: PARTUUID=992231d4-02 instead of /dev/mmcblk0p2 
    #     sed -i "s/PARTUUID=$PARTUUID1/\/dev\/mmcblk0p1/" /etc/fstab
    #     sed -i "s/PARTUUID=$PARTUUID2/\/dev\/mmcblk0p2/" /etc/fstab

    #     echo -e "\
    # \n# For Debian Jessie \
    # \ntmpfs           /tmp            tmpfs   nosuid,nodev         0       0 \
    # \ntmpfs           /var/log        tmpfs   nosuid,nodev         0       0 \
    # \ntmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0 \
    # " >> /etc/fstab

    echo -e "[ info ] 修改 /etc/fstab 完毕 ."
}

# ____________________________________________________________________________

step11(){
    echo -e "[ info ] 移除无关软件与服务 ..."

        if [ $no_network != 0 ]; then

            apt-get remove --purge -y wolfram-engine \
                triggerhappy \
                anacron \
                logrotate \
                dphys-swapfile \
                xserver-common \
                lightdm && \

            insserv -r x11-common && \
            apt-get autoremove --purge

        fi

    echo -e "[ info ] 移除无关软件与服务 完毕 ."
}

# ____________________________________________________________________________

step12(){
    echo -e "[ info ] 用 busybox 替代默认日志管理器 ..."

        # apt-get install -y busybox-syslogd && dpkg --purge rsyslog

    echo -e "[ info ] 用 busybox 替代默认日志管理器 完毕 ."
}

# ____________________________________________________________________________

step13(){
    echo -e "[ info ] 停用关于 交换分区 和 文件系统 的检查, 并设置为 只读 ..."

        sed -i 's/$/& fastboot noswap ro/g' /boot/cmdline.txt
        cat /boot/cmdline.txt

    echo -e "[ info ] 停用关于 交换分区 和 文件系统 的检查, 并设置为 只读 完毕 ."
}

# ____________________________________________________________________________

step14(){
    echo -e "[ info ] 移动部分系统文件到临时文件系统 ..."

        rm -rf /var/lib/dhcp/ /var/lib/dhcpcd5 /var/run /var/spool /var/lock /etc/resolv.conf
        ln -s /tmp /var/lib/dhcp
        ln -s /tmp /var/lib/dhcpcd5
        ln -s /tmp /var/run
        ln -s /tmp /var/spool
        ln -s /tmp /var/lock
        touch /tmp/dhcpcd.resolv.conf
        ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf
        chmod 1777 /tmp

    echo -e "[ info ] 移动部分系统文件到临时文件系统 完毕 ."
}

# ____________________________________________________________________________

step15(){
    echo -e "[ info ] 对于 Raspberry PI 3, 移动部分锁定文件到临时文件系统 ..."

        echo -e "[ info ] 针对 /etc/systemd/system/dhcpcd5 ..."
            sed -i "s/PIDFile=\\/run\\/dhcpcd.pid/PIDFile=\\/var\\/run\\/dhcpcd.pid/" /etc/systemd/system/dhcpcd5
            cat /etc/systemd/system/dhcpcd5
        echo -e "[ info ] 好了 ."

        echo -e "[ info ] 针对 /var/lib/systemd/random-seed ..."
            rm /var/lib/systemd/random-seed    
            ln -s /tmp/random-seed /var/lib/systemd/random-seed
            sed -i "/RemainAfterExit=yes/aExecStartPre=\\/bin\\/echo '' >\\/tmp\\/random-seed" /lib/systemd/system/systemd-random-seed.service    
        echo -e "[ info ] 好了 ."

        echo -e "[ info ] daemon reloading ..."
            systemctl daemon-reload
        echo -e "[ info ] daemon reloaded ."

    echo -e "[ info ] 对于 Raspberry PI 3, 移动部分锁定文件到临时文件系统 完毕 ."
}

# ____________________________________________________________________________

step16(){
    echo -e "[ info ] 修改 /etc/cron.hourly/fake-hwclock ..."

        sed -i "/fake-hwclock save/i\ \ mount -o remount,rw \/" /etc/cron.hourly/fake-hwclock

        sed -i "/fake-hwclock save/a\ \ mount -o remount,ro \/" /etc/cron.hourly/fake-hwclock

    echo -e "[ info ] 修改 /etc/cron.hourly/fake-hwclock 完毕 ."

    echo -e "[ info ] 修改 /etc/ntp.conf ..."

        sed -i "s/driftfile\ \/var\/lib\/ntp\/ntp.drift/driftfile \/var\/lib\/tmp\/ntp.drift/" /etc/ntp.conf

    echo -e "[ info ] 修改 /etc/ntp.conf 完毕 ."
}

# ____________________________________________________________________________

step17(){
    echo -e "[ info ] 移除部分启动脚本 ..."

        insserv -r bootlogs 
        insserv -r console-setup

    echo -e "[ info ] 移除部分启动脚本 完毕 ."
}

# ____________________________________________________________________________

step18(){
    echo -ne "[ info ] 设置 dhcpcd 服务超时(20s) ..."
        echo "DefaultTimeoutStartSec=20s" >> /etc/systemd/system.conf
    echo "好了 ."

    echo -e "[ info ] 禁用 mysql 服务开机启动 ..."
        systemctl disable mysql.service
    echo "好了 ."

    systemctl daemon-reload

    # echo -e "[ info ] 增加动态切换 ro <=> rw 命令 ..."

    #     echo -e "\
    # \n# set variable identifying the filesystem you work in (used in the prompt below) \
    # \nset_bash_prompt(){ \
    # \n    fs_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p") \
    # \n    PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' \
    # \n} \
    # \nalias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot' \
    # \nalias rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot' \
    # \n# setup fancy prompt \
    # \nPROMPT_COMMAND=set_bash_prompt
    # " >> /etc/bash.bashrc
}

# ____________________________________________________________________________
# winux
step19(){
    echo -ne "[ stage ] 是否启用 RTC ? [y/n] "

    read cmd
    if [ "$cmd" == "y" ]; then
        
        echo -ne "[ info ] 修改 /boot/config.txt ..."
            if grep -Fxq "dtoverlay=i2c-rtc,ds1307" /boot/config.txt; then
                echo -n ""
            else
                echo -e "\ndtoverlay=i2c-rtc,ds1307" >> /boot/config.txt
            fi
        echo -e "好了 ."
        echo -e "[ info ] RTC 已启用为: dtoverlay=i2c-rtc,ds1307 ."

        if [ "`which fake-hwclock`" != "" ]; then

            echo -e "[ info ] 移除 fwclock ..."
                sudo apt-get -y remove fake-hwclock
                sudo update-rc.d -f fake-hwclock remove
                sudo systemctl disable fake-hwclock
            echo -e "[ info ] 移除 fwclock 完毕 ."
        
        fi

        echo -ne "[ info ] 修改 /lib/udev/hwclock-set ..."

cat << "EOF" > /lib/udev/hwclock-set
#!/bin/sh
# Reset the System Clock to UTC if the hardware clock from which it
# was copied by the kernel was in localtime.

dev=$1

#if [ -e /run/systemd/system ] ; then
#    exit 0
#fi

if [ -e /run/udev/hwclock-set ]; then
    exit 0
fi

if [ -f /etc/default/rcS ] ; then
    . /etc/default/rcS
fi

# These defaults are user-overridable in /etc/default/hwclock
BADYEAR=no
HWCLOCKACCESS=yes
HWCLOCKPARS=
HCTOSYS_DEVICE=rtc0
if [ -f /etc/default/hwclock ] ; then
    . /etc/default/hwclock
fi

if [ yes = "$BADYEAR" ] ; then
    /sbin/hwclock --rtc=$dev --systz --badyear
    /sbin/hwclock --rtc=$dev --hctosys --badyear
else
    /sbin/hwclock --rtc=$dev --systz
    /sbin/hwclock --rtc=$dev --hctosys
fi

# Note 'touch' may not be available in initramfs
> /run/udev/hwclock-set
EOF

        echo -e "好了 ."
    else
        echo -e "[ info ] 你选择了不启用($cmd 而非 y) 跳过 ."
    fi
}

# ____________________________________________________________________________
# winux
step20(){
    echo -ne "[ stage ] 重启 ? [yes/no] "

    read cmd
    if [ "$cmd" == "yes" ]; then
        ps aux | grep "iptalk" | awk '{print$2}' | xargs kill -9
        systemctl reboot
    else
        echo -e "你选择了不重启($cmd 而非 yes) 稍候使用 systemctl reboot 来重启 ."
    fi
}

# ____________________________________________________________________________

if [ "$precondition" == "local" ]; then

    # if [ "`mount | grep '/dev/mmcblk0p2 on / type ext4 (ro,noatime,data=ordered)'`" != "" ]; then
    #     echo -e "[ info ] 你是从 windows 过来的吧, 没加 windows 参数 . 算了 . 继续 ."
    #     precondition=winux
    # else

        mount -o remount,rw /
        mount -o remount,rw /boot

        init

        for k in $( seq $step $max_step )
        do
            echo -e "----------- ----------- -----------"
            next $k
            echo -e "\n----------- 第 $step / $max_step 步 -----------"
            step$k
        done
    # fi

fi

if [ "$precondition" == "winux" ]; then

    # 这个流程可以重复执行

    mount -o remount,rw /
    mount -o remount,rw /boot

    init

    for k in 1 2 3 4 6 7 8 9 10 19 20
    do
        echo -e "----------- ----------- -----------"
        next $k
        echo -e "\n----------- 第 $k / $max_step 步 -----------"
        step$k
    done
fi

end 0
