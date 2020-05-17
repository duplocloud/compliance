#!/bin/bash
mkdir -p /home/clamav
cd /home/clamav
wget -O clamavrunscan.sh https://raw.githubusercontent.com/duplocloud/compliance/master/clamavrunscan.sh
chmod 0755 clamavrunscan.sh
unlink /etc/cron.hourly/clamscan_hourly
ln /home/clamav/clamavrunscan.sh /etc/cron.hourly/clamscan_v1_hourly
exit 0