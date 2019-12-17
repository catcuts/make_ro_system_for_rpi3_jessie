echo -e "\t\t开始"

if [ "$2" == "" ]; then
    echo -e "未指定盘符 . 中止 ."
    exit 0
fi

ls $2 > /dev/null
if [ $? -ne 0 ]; then
    echo -e "$2 不存在 . 中止 ."
    exit 0
fi

ls $1 > /dev/null
if [ $? -ne 0 ]; then
    echo -e "$1 不存在 . 中止 ."
    exit 0
fi

df -h | grep $2 | awk '{print$6}' | xargs ls -l

echo -ne "\n\n确认以上 $2 挂载文件系统允许格式化 ！ [yes/no] "

read allow

if [ "$allow" != "yes" ]; then
    echo -e "你选择了不允许($done_prepare 而非 yes) . 中止 ."
    exit 0
fi

df -h | grep /dev/sdb | awk '{print$6}' | xargs umount && \

yes | mkfs -t ext4 $2 && \

echo -e "正在向 $2 写入系统 ..."

sudo gzip -dc $1 | sudo dd of=$2

echo -e "写入完毕 ."

