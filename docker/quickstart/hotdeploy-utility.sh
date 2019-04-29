#!/bin/bash
source /etc/environment

# Wait for server1 to start
/usr/local/bin/dockerize -wait tcp://localhost:17010 -timeout 10m

# add a new wait time
sleep 5

find /opt/hot-deploy/ -type f -exec touch {} \;
