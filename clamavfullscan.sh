#!/bin/bash
#
LOGFILE="/var/log/clamav/clamav-$(date +'%Y-%m-%d').log";
DIRTOSCAN="/home";

# Update ClamAV database
echo "Looking for ClamAV database updates...";
freshclam --quiet;

echo "Starting a full weekend scan.";
mkdir -p /quarantined-virus

# be nice to others while scanning the entire root
nice -n5 clamscan -ri / --exclude-dir=/sys/ --exclude-dir=/quarantined-virus --stdout | logger -i -t clamd & cpulimit -l 30 -z -e clamscan;

exit 0
