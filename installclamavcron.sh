#!/bin/bash
mkdir -p /home/clamav
cd /home/clamav
wget https://raw.githubusercontent.com/duplocloud/compliance/master/clamavrunscan.sh
chmod 0755 clamavrunscan.sh
ln /home/clamav/clamavrunscan.sh /etc/cron.hourly/clamscan_hourly
exit 0