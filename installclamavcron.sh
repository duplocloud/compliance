#!/bin/bash
mkdir -p /home/clamav
cd /home/clamav
wget -O clamavnormalscan.sh https://raw.githubusercontent.com/duplocloud/compliance/master/clamavnormalscan.sh
wget -O clamavfullscan.sh https://raw.githubusercontent.com/duplocloud/compliance/master/clamavfullscan.sh
chmod 0755 clamavnormalscan.sh
chmod 0755 clamavfullscan.sh
unlink /etc/cron.hourly/clamscan_v1_hourly
unlink /etc/cron.daily/clamscan_daily
unlink /etc/cron.weekly/clamscan_weekly
ln /home/clamav/clamavnormalscan.sh /etc/cron.daily/clamscan_daily_v2
ln /home/clamav/clamavfullscan.sh /etc/cron.weekly/clamscan_weekly_v2
exit 0
