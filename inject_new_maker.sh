
old=/home/pi/make_ro_system_for_rpi3_jessie

new=make_ro_system_for_rpi3_jessie

if [ -d $old ]; then

    echo -ne "移除旧的 ..."

        sudo rm -rf $old/*

    echo -e "好了 ."

else

    mkdir -p $old

fi

echo -ne "移入新的 ..."

if [ -d $new ]; then

    sudo cp -r $new/* $old/

    echo -e "好了 ."

    echo -e "完成 ."

else

    echo -e "错误 ! 新的文件夹不存在 . 中止 ."

fi
