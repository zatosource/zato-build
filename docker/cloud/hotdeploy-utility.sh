#!/bin/bash
source /etc/environment

# Wait for server1 to start
/usr/local/bin/dockerize -wait http://localhost:17010/zato/ping -timeout 10m || exit 1

# add a new wait time
sleep 60

set -x
if [[ -d "/opt/hot-deploy" && -n "$(find /opt/hot-deploy/ -type f)" ]]; then
    for (( i = 0; i < 3; i++ )); do
        find /opt/hot-deploy/ -type f -exec touch {} \;
        sleep 20
    done
fi
set +x
