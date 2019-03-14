#!/bin/bash
source /etc/environment

cd /opt/zato/env/qs-1 || exit 1
set -x # enable show commands
/opt/zato/current/bin/zato quickstart create --verbose --odb_host "localhost" --odb_port 5432 --odb_user "zato" --odb_password "mysupersecretpassword" --odb_db_name "zato" --kvdb_password '' /opt/zato/env/qs-1/ postgresql localhost 6379
/opt/zato/current/bin/zato from-config --verbose /opt/zato/update_password.config || exit 1
sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/qs-1/load-balancer/config/repo/zato.config || exit 1
sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server1/config/repo/server.conf || exit 1
sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server2/config/repo/server.conf || exit 1
set +x # disable show commands
