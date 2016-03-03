#!/bin/bash -eux

sudo su - zato -c "rm -rf /opt/zato/env/qs-1 && mkdir -p /opt/zato/env/qs-1"
cd /opt/zato/env/qs-1
sudo su - zato -c "/opt/zato/current/bin/zato quickstart create . sqlite localhost 6379 --verbose --kvdb_password ''"
sudo su - zato -c "sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/qs-1/load-balancer/config/repo/zato.config"
sudo su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server1/config/repo/server.conf"
sudo su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server2/config/repo/server.conf"
