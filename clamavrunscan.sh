#!/bin/bash
#
LOGFILE="/var/log/clamav/clamav-$(date +'%Y-%m-%d').log";
DIRTOSCAN="/home";

# Update ClamAV database
echo "Looking for ClamAV database updates...";
freshclam --quiet;

TODAY=$(date +%u);

if [ "$TODAY" == "6" ];then
 echo "Starting a full weekend scan.";

 # be nice to others while scanning the entire root
 nice -n5 clamscan -ri / --exclude-dir=/sys/ --stdout| logger -i -t clamd;
else
 DIRSIZE=$(du -sh "$DIRTOSCAN" 2>/dev/null | cut -f1);

 echo "Starting a daily scan of "$DIRTOSCAN" directory.
 Amount of data to be scanned is "$DIRSIZE".";

 clamscan -ri "$DIRTOSCAN" --stdout| logger -i -t clamd;
fi
exit 0