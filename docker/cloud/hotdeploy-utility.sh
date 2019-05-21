#!/bin/bash
source /etc/environment

# Wait for server1 to start
/usr/local/bin/dockerize -wait http://localhost:17010/zato/ping -timeout 10m || exit 1

# add a new wait time
sleep 60

set -x
if [[ -n "$(find /opt/hot-deploy/ -type f)" ]]; then
    find /opt/hot-deploy/ -type f -exec touch {} \;
fi
set +x
