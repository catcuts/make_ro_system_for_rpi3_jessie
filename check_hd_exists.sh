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
        exit 1
    fi

echo -e "[ info ] 检查硬盘 正常 ."

# ____________________________________________________________________________