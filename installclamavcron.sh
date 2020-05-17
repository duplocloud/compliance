#!/bin/bash
mkdir -p /home/clamav
cd /home/clamav
curl -H "Accept: application/vnd.github.v3.raw" -O -L https://api.github.com/repos/duplocloud/compliance/clamavrunscan.sh
chmod 0755 clamavscan.sh
ln /home/clamav/clamavscan.sh /etc/cron.hourly/clamscan_hourly
exit 0