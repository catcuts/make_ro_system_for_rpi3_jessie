# 构建树莓派只读文件系统 + 可写移动硬盘 运行 iptalk + mysql （提高断电耐受能力）
___
## 目录

[在 windows 下使用工具写入该系统](#第-1-种方式：在-windows-下使用工具写入该系统)

[在 linux 下使用工具写入该系统](#第-2-种方式：在-linux-下使用工具写入该系统)

[在运行中的联网树莓派上自动构建该系统](#第-3-种方式：在运行中的联网树莓派上自动构建该系统)

___
## 概述

　　三种构建方式：

1. 数据库备份 -> 在 windows 下使用工具写入该系统 -> 下载自动构建程序 -> 放入数据库备份和源码 -> 运行自动构建程序
<br><br>
2. 数据库备份 -> 在 linux 下使用工具写入该系统 -> 下载自动构建程序 -> 放入数据库备份和源码 -> 运行自动构建程序
<br><br>
3. 下载自动构建程序 -> 放入数据库备份和源码 -> 运行自动构建程序

　　推荐在联网状态下使用第 3 种方式，速度最快。如果实在不能联网，则选择第 1 或 第 2 种方式。

___
## 第 1 种方式：在 windows 下使用工具写入该系统

**1. 登入树莓派**

```shell
ssh root@<树莓派 ip 地址>
```

**2. 停止 iptalk 程序 / web 端**

　　注：如有必要，先询问用户是否可以停止！

　　首先：
  
```shell
ps aux | grep "iptalk" | awk '{print$2}' | xargs kill -9
```
　　然后：
  
```shell
ps aux | grep "test" | awk '{print$2}' | xargs kill -9
```

**3. 备份 iptalk 数据库**

　　首先：
  
```shell
mysqldump -uroot -proot iptalk > /home/pi/iptalk_bkup_before_ro.sql
```

　　然后：使用 `Filezilla` 将其复制到本机（远程该树莓派的主机）上保存。

**4. 重装树莓派系统**

　　首先：使用 `SDFormatter` 格式化 SD 卡，完毕后重新拔插。

　　然后：使用 `win32diskimager` 将 `iptalk_0.5.7_readonly-filesystem-with-hard-drive_20180728_lth.img` 写入 SD 卡。
  
**5. 下载自动构建程序**

　　首先：开机。

　　然后：使用 `Filezilla` 将 `release_make_ro_system` 目录下的内容复制到树莓派上。
  
**6. 放入数据库和源码**

　　使用 `Filezilla` 将数据库和源码复制到树莓派的 `release_make_ro_system` 目录下。

**7. 运行自动构建程序**

　　首先：登入树莓派，进入 `release_make_ro_system`。
  
　　然后：`bash make_ro_system_sp.sh windows`

___
## 第 2 种方式：在 linux 下使用工具写入该系统

**1. 登入树莓派**

```shell
ssh root@<树莓派 ip 地址>
```

**2. 停止 iptalk 程序 / web 端**

　　注：如有必要，先询问用户是否可以停止！

　　首先：
  
```shell
ps aux | grep "iptalk" | awk '{print$2}' | xargs kill -9
```
　　然后：
  
```shell
ps aux | grep "test" | awk '{print$2}' | xargs kill -9
```

**3. 备份 iptalk 数据库**

　　首先：
  
```shell
mysqldump -uroot -proot iptalk > /home/pi/iptalk_bkup_before_ro.sql
```

　　然后：使用 `Filezilla` 将其复制到本机（远程该树莓派的主机）上保存。

**4. 重装树莓派系统**

　　注：`/dev/sdy` 应指定为具体的设备。

　　`sudo gzip -dc /path/to/iptalk_0.5.7_readonly-filesystem-with-hard-drive_20180728_lth.gz | sudo dd of=/dev/sdy`
  
**5. 下载自动构建程序**

　　首先：开机。

　　然后：使用 `Filezilla` 将 `release_make_ro_system` 目录下的内容复制到树莓派上。
  
**6. 放入数据库和源码**

　　使用 `Filezilla` 将数据库和源码复制到树莓派的 `release_make_ro_system` 目录下。

**7. 运行自动构建程序**

　　首先：登入树莓派，进入 `release_make_ro_system`。
  
　　然后：`bash make_ro_system_sp.sh linux`

___
## 第 3 种方式：在运行中的联网树莓派上自动构建该系统

**1. 下载自动构建程序**

　　首先：开机。

　　然后：使用 `Filezilla` 将 `release_make_ro_system` 目录下的内容复制到树莓派上。
  
**2. 放入数据库和源码**

　　使用 `Filezilla` 将数据库和源码复制到树莓派的 `release_make_ro_system` 目录下。

**3. 运行自动构建程序**

　　首先：登入树莓派，进入 `release_make_ro_system`。
  
　　然后：`bash make_ro_system_sp.sh`

附：[第 3 种方式的操作视频](https://www.bilibili.com/video/av28346666/)
