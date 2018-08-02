#!/usr/bin/bash

# this script can start iptalk on rpi3 from mysql not running

MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_CTNER=mysql-server
MYSQL_TIMEOUT=100

checking_interval=0.1
checking_timeout=$MYSQL_TIMEOUT
checking_not_ok=1

mysql -u root -proot -h$MYSQL_HOST -P$MYSQL_PORT -e "select version();" &> /dev/null
if [ $? -eq 0 ]; then
    checking_not_ok=0
    # echo -e "\t$MYSQL_CTNER is ready ."
else
    mysqld --user=mysql &> /dev/null &
fi

while [ checking_not_ok ]; do
    echo -n "请等待 mysql 配置，还有 $checking_timeout ……"
    mysql -u root -proot -h$MYSQL_HOST -P$MYSQL_PORT -e "select version();" &> /dev/null
    if [ $? -eq 0 ]; then
        checking_not_ok=0
        echo -e "\t$MYSQL_CTNER is ready ."
        mysql -uroot -proot -e 'SHOW VARIABLES WHERE Variable_Name LIKE "%dir"'
        break
    fi
    if [ $checking_timeout -ne 0 ]; then
        ((checking_timeout--))
        sleep 0.1
    else
        echo -e "\t$MYSQL_CTNER timeout !"
        exit 1
    fi
    echo -ne "\r                                        \r"
done

ps aux | grep iptalk.py | awk '{print$2}' | xargs kill -9

# # this function is called when Ctrl-\ is sent
# function trap_ctrlslash ()
# {
#     # perform cleanup here
#     ps aux | grep iptalk.py | awk '{print$2}' | xargs kill -9

#     # exit shell script with error code 2
#     # if omitted, shell script will continue execution
#     exit 3
# }

# # initialise trap to call trap_ctrlc function
# # when signal 2 (SIGINT) is received
# trap "trap_ctrlslash" 3
echo -e "\033[31m\033[01m\033[05m[ 按 CTRL + \ 退出 ]\033[0m"
python /home/pi/hd/src/iptalk.py
