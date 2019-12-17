#!/bin/bash
step=1
#↑ 停留在第几步, 该步之前已经执行完毕
max_step=19

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

check_params(){
    if [ `echo $1 $max_step | awk '{if($1>=$2 || $1<=0){printf"sb"}else{printf"ok"}}'` == "sb" ]; then
        echo -e "\033[31m\033[01m\033[05m[ erro ]\033[0m 步数越界! 中止 ."
        exit 1
    else
        echo 很正常啊
    fi
}

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

if [ "$base_dir" == "/home*" ]; then
    echo -e "${Red}[ erro ]${NC} 不要把我放在 /home 目录下 . 中止 ."
fi

# ____________________________________________________________________________

sbs="yes"
if [ "$1" == "notstepbystep" ]; then
    sbs="no"
else
    echo -e "[ info ] 已启用: 步步模式(step-by-step mode) ."
fi

# 每一步执行完毕时调用, 则 step 自增 1 (如: 第 1 步执行完毕, step=2, 即当前位(开始)于第 2 步)
next(){
    last_step=$step
    if [ $step -le $max_step ]; then
        ((step++))
    fi
    sed -i "2s/step=$last_step/step=$step/" $0
    if [ "$sbs" == "yes" ]; then
        echo -ne "[ stage ] 继续 ? [y/n] "
        read sbs_cmd
        if [ "$sbs_cmd" != "y" ]; then
            echo -e "${Red}中止 .${NC}"
            exit 1
        fi
    fi
}

is_it_ok(){
    echo -ne "${Brown_Orange}[ warn ]${NC} 没错吧 ？ [y/n] "
    read no_problem
    if [ "$no_problem" != "y" ]; then
        echo -e "${Red}中止 .${NC}"
        exit 1
    fi
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

check_partition(){
    echo -ne "[ info ] 检查分区(/dev/mmcblk0p2) ..."
        if [ "`df -h | grep /dev/root | awk '{print$2}'`" != "3.6G" ]; then
            echo -e "\n${Red}[ erro ]${NC} 分区 /dev/mmcblk0p2 空间未扩展至 3.6G ! 中止 ."
            exit 1
        fi
    echo "完毕 ."

    echo -ne "[ info ] 检查分区(/dev/mmcblk0p3) ..."
        P3UUID=`blkid /dev/mmcblk0p3 | sed -n 's/.*UUID=\"\([^"]*\)\".*/\1/p'`
        P3TYPE=`blkid /dev/mmcblk0p3 | sed 's/.*TYPE="\([^"]*\)".*/\1/'`
        if [[ "$P3UUID" == "" || "$P3TYPE" != "ext4" ]]; then
            echo -e "\n${Red}[ erro ]${NC} 分区 /dev/mmcblk0p3 不存在或类型错误 ! 中止 ."
            exit 1
        fi
    echo "完毕 ."
}

P3UUID=`blkid /dev/mmcblk0p3 | sed -n 's/.*UUID=\"\([^"]*\)\".*/\1/p'`
P3TYPE=`blkid /dev/mmcblk0p3 | sed 's/.*TYPE="\([^"]*\)".*/\1/'`

# ____________________________________________________________________________

step1(){
    echo -e "[ info ] 移除无关软件与服务 ..."

        apt-get remove -y --purge wolfram-engine \
            triggerhappy \
            lightdm && \

        insserv -r x11-common && \
        apt-get autoremove --purge -y

    echo -e "[ info ] 移除无关软件与服务 完毕 ."

    echo -e "下一步: 创建 admin 用户"

    # echo -ne "重启 ? [yes/no] "
    # read confirmed
    # if [ "$confirmed" != "yes" ]; then
    #     echo -e "${Red}[ erro ]${NC} 你选择了取消继续($confirmed 而非 yes) . 中止 . 重启后再试 ."
    #     exit 1
    # fi
}

step2(){
    echo -ne "[ info ] 修正系统参数 ..."
        echo "vm.mmap_min_addr = 4096" >  /etc/sysctl.d/mmap_min_addr.conf
    echo -e "好了 . "

    echo -ne "[ info ] 创建并授权用户 admin 用于维护 ..."

        (
        echo hly012501
        echo hly012501
        echo Martain Tester King  # Full Name []: 
        echo 124850   # Room Number []: 
        echo 666666   # Work Phone []: 
        echo 88888888 # Home Phone []: 
        echo Meow     # Other []: 
        echo y        # Is the information correct? [Y/n] 
        ) | adduser admin &> /dev/null

        id admin > /dev/null
        if [ $? -ne 0 ]; then
            echo -e "\n${Red}[ erro ]${NC} 创建维护用户失败 . 中止 ."
            exit 1
        fi

        sed -ie '/admin[[:blank:]]*ALL=(ALL:ALL)[[:blank:]]*ALL/d' /etc/sudoers

        sed -i '/root[[:blank:]]*ALL=(ALL:ALL)[[:blank:]]*ALL/a\admin    ALL=(ALL:ALL) ALL' /etc/sudoers

    echo -e "好了 ."

    echo -e "下一步: 创建新分区"
}

# ____________________________________________________________________________

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
        echo +7549747  # last sector
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

check(){
    echo -e "检查: ($2)"
    du -h --max-depth=1 $2
    if [ -d $1 ]; then
        echo -e "对应源文件为: ($1)"
        du -h --max-depth=1 $1
        echo -ne "确认备份无误 ? [yes/no] "
        read checked
        if [ "$checked" != "yes" ]; then
            echo -e "${Red}[ erro ]${NC} 你认为备份有误($checked 而非 yes) . 中止 . 检查备份文件后再试 ."
            exit 1
        fi
    else
        echo -e "${Red}[ erro ]${NC} 对应源文件不存在 ?! 中止 ."
        exit 1
    fi
}

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
        echo -e "${Red}[ erro ]${NC} 硬盘不是 ext4 格式. 中止 . 自行格式化后重试 ."
        exit 1
    fi

    # ________________________________________________________________________

    echo -ne "[ info ] 挂载 /dev/mmcblk0p3 到 /var_temp (新分区挂载点) ..."
        if [ ! -d /var_temp ]; then
            mkdir -p /var_temp
        fi
        mount /dev/mmcblk0p3 /var_temp
        mounted=`df -h | grep /dev/mmcblk0p3 | awk '{print$6}'`
        if [ "$mounted" != "/var_temp" ]; then
            echo -e "\n${Red}[ erro ]${NC} 挂载硬盘失败. 中止 . 检查后重试 ."
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

    echo -e "下一步: 更换软件源"
}

# ____________________________________________________________________________

step5(){
    echo -ne "[ info ] 更换软件源 ..."

cat << EOF > /etc/apt/sources.list
# alicloud
deb http://mirrors.aliyun.com/raspbian/raspbian/ wheezy main non-free contrib rpi
deb-src http://mirrors.aliyun.com/raspbian/raspbian/ wheezy main non-free contrib rpi

# original
#deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi
EOF

    echo "好了 ."

    echo -e "[ info ] 更新软件 ..."
        apt-get update
    echo -e "[ info ] 更新软件 完毕 ."

    echo -e "下一步: 安装 python 3.6.5"
}

# ____________________________________________________________________________

step6(){
    echo -e "[ info ] 安装 python 3.6.5 ..."
        if [ "`which python3.6`" == "" ]; then
            echo -e "[ info ] 安装编译依赖 ..."
                apt-get install -y build-essential checkinstall \
                tk-dev \
                libncurses5-dev \
                libncursesw5-dev \
                libreadline6-dev \
                libdb5.3-dev \
                libgdbm-dev \
                libsqlite3-dev \
                libssl-dev \
                libbz2-dev \
                libexpat1-dev \
                liblzma-dev \
                zlib1g-dev
            echo -e "[ info ] 安装编译依赖 完毕 ."
            is_it_ok

            echo -e "[ info ] 编译 python 3.6.5 ..."
                mkdir -p /var_temp/download
                cd /var_temp/download/
                cp $base_dir/Python-3.6.5.tar.xz ./
                tar xf Python-3.6.5.tar.xz
                cd Python-3.6.5
                ./configure
                make
                make altinstall
            echo -e "[ info ] 编译 python 3.6.5 完毕 ."
            is_it_ok

            echo -e "[ info ] 清理编译依赖 ..."
                apt-get remove --purge -y build-essential checkinstall tk-dev
                apt-get remove --purge -y libncurses5-dev libncursesw5-dev libreadline6-dev
                apt-get remove --purge -y libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev
                apt-get remove --purge -y libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev
                apt-get -y autoremove
                apt-get -y clean
            echo -e "[ info ] 清理编译依赖 完毕 ."

            cd $base_dir
        fi
    echo -e "[ info ] 安装 python 3.6.5 完毕 ."

    echo -e "下一步: 安装 gcc 4.8 和 g++ 4.8"
}

# ____________________________________________________________________________

step7(){
    echo -e "[ info ] 安装 gcc 4.8 和 g++ 4.8 ..."

        echo -ne "[ info ] 修改 /etc/apt/sources.list ..."
cat << EOF > /etc/apt/sources.list
deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi
deb http://archive.raspbian.org/raspbian wheezy main contrib non-free rpi
# Source repository to add
deb-src http://archive.raspbian.org/raspbian wheezy main contrib non-free rpi
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi
deb http://archive.raspbian.org/raspbian jessie main contrib non-free rpi
# Source repository to add
deb-src http://archive.raspbian.org/raspbian jessie main contrib non-free rpi
EOF
        echo "好了 ."

        echo -ne "[ info ] 修改 /etc/apt/preferences ..."
cat << EOF > /etc/apt/preferences
Package: *
Pin: release n=wheezy
Pin-Priority: 900
Package: *
Pin: release n=jessie
Pin-Priority: 300
Package: *
Pin: release o=Raspbian
Pin-Priority: -10
EOF
        echo "好了 ."

        echo -e "[ info ] 更新软件源 ..."
            sudo apt-get update -y
        echo -e "[ info ] 更新软件源 完毕 ."

        echo -e "[ info ] 安装 gcc 4.8 和 g++ 4.8 ..."
            sudo apt-get install -y -t jessie gcc-4.8 g++-4.8
        echo -e "[ info ] 安装 gcc 4.8 和 g++ 4.8 完毕 ."

        is_it_ok

        echo -ne "[ info ] 移除旧的 gcc/g++ 替换项 ..."
            sudo update-alternatives --remove-all gcc 
            sudo update-alternatives --remove-all g++
        echo "好了 ."

        echo -ne "[ info ] 安装新的 gcc/g++ 替换项 ..."
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 20
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
            sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 20
            sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
        echo "好了 ."

        echo -e "[ info ] 恢复软件源 ..."

cat << EOF > /etc/apt/sources.list
# alicloud
deb http://mirrors.aliyun.com/raspbian/raspbian/ wheezy main non-free contrib rpi
deb-src http://mirrors.aliyun.com/raspbian/raspbian/ wheezy main non-free contrib rpi

# original
#deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi
EOF

        rm /etc/apt/preferences

        apt-get update

        echo -e "[ info ] 恢复软件源 完毕 ."

        echo -e "[ info ] 检查: "
        gcc --version
        g++ --version

        is_it_ok

    echo -e "[ info ] 安装 gcc 4.8 和 g++ 4.8 完毕 ."

    echo -e "下一步: 安装 node 10.8.0"
}

# ____________________________________________________________________________

step8(){
    echo -ne "[ info ] 安装 node 10.8.0 ..."
        tar xvzf $base_dir/node* > /dev/null
        if [ ! -d /opt/node ]; then
            mkdir /opt/node
        fi
        cp -a $base_dir/node*/* /opt/node

        if [ "`grep /opt/node/bin /root/.profile`" == "" ]; then
            echo "PATH=$PATH:/opt/node/bin" >> /root/.profile
            echo "export PATH" >> /root/.profile
            PATH=$PATH:/opt/node/bin
            export PATH
        fi

        source ~/.profile

        if [ "`grep /opt/node/bin /home/admin/.profile`" == "" ]; then
            echo "PATH=$PATH:/opt/node/bin" >> /home/admin/.profile
            echo "export PATH" >> /home/admin/.profile
            PATH=$PATH:/opt/node/bin
            export PATH
        fi

        if [ "`grep /opt/node/bin /etc/sudoers`" == "" ]; then
            sed -i 's/\(Defaults[[:blank:]]*secure_path="[^"]*\)"/\1:\/opt\/node\/bin"/' /etc/sudoers
        fi
        
        sudo node -v && sudo npm -v > /dev/null
        if [ $? -ne 0 ]; then
            echo -e "\n${Red}[ erro ]${NC} 安装失败 . 中止 ."
            exit 1
        fi

        # (echo hly012501) | su admin
        # if [ $? -ne 0 ]; then
        #     su admin
        # fi
        # me=`whoami`
        # if [ "$me" != "admin" ]; then
        #     echo -e "${Red}[ erro ]${NC} 用户切换失败 . 中止 ."

    echo -e "[ info ] 安装 node 10.8.0 完毕 ."

    echo -e "下一步: 启用 GPIO 串口"
    exit 1
}

# ____________________________________________________________________________

step9(){
    echo -e "[ info ] 启用 GPIO 串口 ..."
    ls /dev/ttyS1 > /dev/null
    if [ $? -ne 0 ]; then
        manufactory=/var_temp/serialport
        mkdir $manufactory

        echo -e "[ info ] 安装编译依赖 ..."
            apt-get install -y libusb-1.0-0-dev libz-dev
        echo -e "[ info ] 安装编译依赖 完毕 ."

        echo -e "[ info ] 安装工具链 ..."
            if [ -d $manufactory/sunxi-tools ]; then
                rm -rf $manufactory/sunxi-tools
            fi
            cp -r -p sunxi-tools $manufactory/
        echo -e "[ info ] 安装工具链 完毕 ."

        echo -e "[ info ] 编译工具链 ..."
            cd $manufactory/sunxi-tools
            make
        echo -e "[ info ] 编译工具链 完毕 ."

        echo -e "[ info ] 修改内核配置(/boot/script.bin) ..."
            cd $manufactory
            cp -p /boot/script.bin $manufactory/script.bin
                cp -p $manufactory/script.bin $manufactory/script.bin.bkup

                $manufactory/sunxi-tools/bin2fex $manufactory/script.bin > $manufactory/script.fex
                
                    sed -i '/\[uart1\]/ { 
                        n # next line
                        s/uart_used = 0/uart_used = 1/
                        n # next line
                        n # next line
                        s/uart_type = 4/uart_type = 2/
                        n
                        n
                        n
                        /^uart_rts/d
                    }' $manufactory/script.fex

                    sed -i '/\[uart1\]/ { 
                        n # next line
                        n # next line
                        n # next line
                        n
                        n
                        n 
                        /^uart_cts/d
                    }' $manufactory/script.fex

                $manufactory/sunxi-tools/fex2bin $manufactory/script.fex > $manufactory/script.bin

                echo -e "${Brown_Orange}[ warn ]${NC} 准备覆盖 /boot/script.bin. 务必检查 $manufactory/script.bin ." 
                is_it_ok

            cp $manufactory/script.bin /boot/script.bin

        echo -e "[ info ] 修改内核配置(/boot/script.bin) 完毕 ."

    else
        echo -e "[ info ] 启用 GPIO 串口 完毕 . 重启后生效 ."
    fi

    echo -e "下一步: 安装 supervisord, 配置 vigserver 和 vigmonitor"
    
    # echo -ne "${Red}[ warn ]${NC} 启用 GPIO 串口了吗 ? [yes/no] "
    # read gpio_enabled
    # if [ "$gpio_enabled" != "yes" ]; then
    #     echo -e "${Red}[ erro ]${NC} 你选择了还没有($gpio_enabled 而非 yes) . 中止 . 手动启用后再试 ."
    #     exit 1
    # else
    #     ls /dev/ttyS1 > /dev/null
    #     if [ $? -ne 0 ]; then
    #         echo -e "${Red}[ erro ]${NC} 骗人 . 中止 . 手动启用后再试 ."
    #         exit 1
    #     fi
    # fi
}

# ____________________________________________________________________________

step10(){
    echo -e "[ info ] 安装 supervisor ..."
        apt-get install -y supervisor
    echo -e "[ info ] 安装 supervisor 完毕 ."

    echo -e "[ info ] 配置 vigserver 和 vigmonitor ..."
        cp -r -p $base_dir/vigserver /var_temp/local/hyt
        cp -r -p $base_dir/vigmonitor /var_temp/local/hyt
        cp $base_dir/vigmonitor.conf /etc/supervisor/conf.d/
        cd $base_dir/packages
        python3.6 -m pip install --no-index --find-links=./ hprose-1.4.3.tar.gz requests-2.19.1.tar.gz
        cd $base_dir/packages/pyA20
        python3.6 setup.py install
        cd $base_dir/
    echo -e "[ info ] 配置 vigserver 和 vigmonitor 完毕 ."

    echo -e "[ info ] 修改 /etc/fstab ..."

cat << "EOF" > /etc/fstab
proc            /proc           proc    defaults             0       0
/dev/mmcblk0p1  /boot           vfat    defaults             0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime     0       1
/dev/mmcblk0p3  /var            ext4    defaults,noatime     0       0
/var/local/home /home           none    defaults,bind        0       0
/var/local/srv  /srv            none    defaults,bind        0       0
/var/local/hyt  /hyt            none    defaults,bind        0       0
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
# a swapfile is not a swap partition, so no using swapon|off from here on, use  dphys-swapfile swap[on|off]  for that
EOF

    echo -e "[ info ] 修改 /etc/fstab 完毕 ."

    (
    echo HuanYuTong@@!*@^^^
    echo HuanYuTong@@!*@^^^
    ) | passwd root

    need_reboot

    exit 0
}

# ____________________________________________________________________________

step11(){
    ls /dev/ttyS1 > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${Red}[ erro ]${NC} GPIO 串口启用失败 . 中止 . 检查后重试 ."
        exit 1
    fi
    echo -e "[ info ] 修改 /etc/fstab ..."

cat << "EOF" > /etc/fstab
proc            /proc           proc    defaults             0       0
/dev/mmcblk0p1  /boot           vfat    defaults,ro          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime,ro  0       1
/dev/mmcblk0p3  /var            ext4    defaults,noatime     0       0
/var/local/home /home           none    defaults,bind        0       0
/var/local/srv  /srv            none    defaults,bind        0       0
/var/local/hyt  /hyt            none    defaults,bind        0       0
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
# a swapfile is not a swap partition, so no using swapon|off from here on, use  dphys-swapfile swap[on|off]  for that
EOF

    echo -e "[ info ] 修改 /etc/fstab 完毕 ."
}

# ____________________________________________________________________________

step12(){
    echo -e "[ info ] 用 busybox 替代默认日志管理器 ..."

        apt-get install -y busybox-syslogd && dpkg --purge rsyslog

    echo -e "[ info ] 用 busybox 替代默认日志管理器 完毕 ."
}

# ____________________________________________________________________________

step13(){
    echo -e "[ info ] 停用关于 交换分区 和 文件系统 的检查, 并设置为 只读 ..."

        dphys-swapfile swapoff
        dphys-swapfile uninstall
        update-rc.d dphys-swapfile remove

        echo -e "[ info ] 检查: "
            free -m

    echo -e "[ info ] 停用关于 交换分区 和 文件系统 的检查, 并设置为 只读 完毕 ."
}

# ____________________________________________________________________________

step14(){
    echo -e "[ info ] 移动部分系统文件到临时文件系统 开始 ..."

        # rm -rf /var/lib/dhcp/ /var/lib/dhcpcd5 /var/run /var/spool /var/lock /etc/resolv.conf
        # ln -s /tmp /var/lib/dhcp
        # ln -s /tmp /var/lib/dhcpcd5
        # ln -s /tmp /var/run
        # ln -s /tmp /var/spool
        # ln -s /tmp /var/lock
        # touch /tmp/dhcpcd.resolv.conf
        # ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

    echo -e "[ info ] 移动部分系统文件到临时文件系统 完毕 ."
}

# ____________________________________________________________________________

step15(){
    echo -e "[ info ] 对于 Raspberry PI 3, 移动部分锁定文件到临时文件系统 ..."

        # echo -e "[ info ] 针对 /etc/systemd/system/dhcpcd5 ..."
        #     sed -i "s/PIDFile=\\/run\\/dhcpcd.pid/PIDFile=\\/var\\/run\\/dhcpcd.pid/" /etc/systemd/system/dhcpcd5
        #     cat /etc/systemd/system/dhcpcd5
        # echo -e "[ info ] 好了 ."

        # echo -e "[ info ] 针对 /var/lib/systemd/random-seed ..."
        #     rm /var/lib/systemd/random-seed    
        #     ln -s /tmp/random-seed /var/lib/systemd/random-seed
        #     sed -i "/RemainAfterExit=yes/aExecStartPre=\\/bin\\/echo '' >\\/tmp\\/random-seed" /lib/systemd/system/systemd-random-seed.service    
        # echo -e "[ info ] 好了 ."

        # echo -e "[ info ] daemon reloading ..."
        #     systemctl daemon-reload
        # echo -e "[ info ] daemon reloaded ."

    echo -e "[ info ] 对于 Raspberry PI 3, 移动部分锁定文件到临时文件系统 完毕."
}

# ____________________________________________________________________________

step16(){
    echo -e "[ info ] 修改 /etc/cron.hourly/fake-hwclock ..."

        sed -i "/fake-hwclock save/i\ \ mount -o remount,rw \/" /etc/cron.hourly/fake-hwclock

        sed -i "/fake-hwclock save/a\ \ mount -o remount,ro \/" /etc/cron.hourly/fake-hwclock

    echo -e "[ info ] 修改 /etc/cron.hourly/fake-hwclock 完毕 ."

    # echo -e "[ info ] 修改 /etc/ntp.conf ..."

    #     sed -i "s/driftfile\ \/var\/lib\/ntp\/ntp.drift/driftfile \/var\/lib\/tmp\/ntp.drift/" /etc/ntp.conf

    # echo -e "[ info ] 修改 /etc/ntp.conf 完毕 ."
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
    #     echo "DefaultTimeoutStartSec=20s" >> /etc/systemd/system.conf
    # echo "好了 ."

    # echo -e "[ info ] 禁用 mysql 服务开机启动 ..."
    #     systemctl disable mysql.service
    echo "好了 ."

    # systemctl daemon-reload
}

# ____________________________________________________________________________

step19(){
    need_reboot

    exit 0
}

# ____________________________________________________________________________

for k in $( seq $step $max_step )
do
    echo -e "\n----------- 第 $step / $max_step 步 -----------"
    step$k
    echo -e "----------- ----------- -----------"
    next
done

echo -e "${Red}恭喜你, 圆满完成 .${NC}"