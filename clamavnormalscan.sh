#!/bin/bash
#
LOGFILE="/var/log/clamav/clamav-$(date +'%Y-%m-%d').log";
DIRTOSCAN="/home";

# Update ClamAV database
echo "Looking for ClamAV database updates...";
freshclam --quiet;
DIRSIZE=$(du -sh "$DIRTOSCAN" 2>/dev/null | cut -f1);

echo "Starting a daily scan of "$DIRTOSCAN" directory.
Amount of data to be scanned is "$DIRSIZE".";
mkdir -p /quarantined-virus
clamscan -ri "$DIRTOSCAN" --stdout --move=/quarantined-virus | logger -i -t clamd & cpulimit -l 30 -z -e clamscan;
exit 0
