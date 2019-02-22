# source=$1
# target=$2
# copy=$3

source="/home/catcuts/Desktop/iptalk_0.5.7_readonly-filesystem-with-hard-drive_20180728_lth.gz"
target="/dev/sdb"
copy="/media/catcuts/0001C44100083553/Documents/catcuts/project/iptalk_raspberry_scripts/make_ro_system_for_rpi3_jessie/make_ro_system_for_rpi3_jessie.zip"

echo -e "\t\t开始"

if [ "$target" == "" ]; then
    echo -e "未指定盘符 . 中止 ."
    exit 0
fi

ls $target > /dev/null
if [ $? -ne 0 ]; then
    echo -e "$target 不存在 . 中止 ."
    exit 0
fi

ls $source > /dev/null
if [ $? -ne 0 ]; then
    echo -e "$source 不存在 . 中止 ."
    exit 0
fi

df -h | grep $target | awk '{print$6}' | xargs ls -l

echo -ne "\n\n确认以上 $target 挂载文件系统允许格式化 ！ [yes/no] "

read allow

if [ "$allow" != "yes" ]; then
    echo -e "你选择了不允许($done_prepare 而非 yes) . 中止 ."
    exit 0
fi

df -h | grep $target | awk '{print$6}' | xargs umount && \
echo meow
yes | mkfs -t ext4 $target && \

echo -e "正在向 $target 写入系统 ..."

sudo gzip -dc $source | sudo dd of=$target

echo -e "写入完毕 ."

if [ -f copy ]; then
    echo -ne "复制 make_ro_system_for_rpi3_jessie ..."
    dest=`df -h | grep $target | grep -v "boot" | awk '{print$6}'`/home/pi/make_ro_system_for_rpi3_jessie
    unzip -q copy -d $dest
    #cp -r copy `df -h | grep $target | grep -v "boot" | awk '{print$6}'`/home/pi/
    echo -e "好了 ."
fi

