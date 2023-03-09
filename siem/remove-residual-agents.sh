#!/bin/bash

# Create a tmp folder to locate agent-groups file
if [ -d "/tmp/agent-groups" ]
then
    rm -rf /tmp/agent-groups
fi
mkdir /tmp/agent-groups 2>/dev/null

# Create a tmp folder to locate agents databases
if [ -d "/tmp/agent-db" ]
then
    rm -rf /tmp/agent-db
fi
mkdir /tmp/agent-db 2>/dev/null

# Create files we don't want to remove
touch /tmp/agent-db/global.db
touch /tmp/agent-db/000.db

# Create agent-groups files for every valid agent in tmp/
for id in $(grep -o '^[[:digit:]]\{3,\}[[:space:]][^!#]' /var/ossec/etc/client.keys | egrep -oh ^[[:digit:]]\{3,\})
do
    touch /tmp/agent-groups/$id
    touch /tmp/agent-db/$id.db
done

# Move residual agent-groups files and databases to tmp folder
# Valid files stay
find /var/ossec/queue/agent-groups/ -name '*.*' -exec mv -n {} /tmp/agent-groups/ \;
find /var/ossec/queue/db/ -name '*.*' -exec mv -n {} /tmp/agent-db/ \;

# Delete tmp content
rm -rf /tmp/agent-groups
rm -rf /tmp/agent-db
