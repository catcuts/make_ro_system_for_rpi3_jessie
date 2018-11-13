#!/usr/bin/bash

ps aux | grep iptalk | awk '{print$2}' | xargs kill -9
ps aux | grep test | awk '{print$2}' | xargs kill -9
reboot