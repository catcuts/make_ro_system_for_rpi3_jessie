chmod 777 /home/pi/reboot.sh
echo -ne "[ info ] 设置定时任务 ..."
    # write out current crontab
    crontab -l > newcron
    # 清除所有遗留定时任务
    sed -i 's/^[^#].*//g' newcron
    # echo new cron into cron file
    echo "0 */1 * * *  /home/pi/check_hd_reboot.sh" >> newcron
    echo "0 0 */2 * *  /home/pi/sweep_old_iptalk_database_bkups.sh" >> newcron
    echo "0 */1 * * *  /home/pi/backup_iptalk_database.sh" >> newcron
    # install new cron file
    crontab newcron
    rm newcron
echo "好了 ."