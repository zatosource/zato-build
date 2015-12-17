#!/bin/bash -eux

# Create and run quickstart environment
sudo su - zato -c "mkdir -p /opt/zato/env/qs-1"
sudo su - zato \
    -c "/opt/zato/current/bin/zato quickstart create
        --odb_host localhost
        --odb_port 5432
        --odb_user zato
        --odb_db_name zato
        --odb_password zato
        --kvdb_password ''
        /opt/zato/env/qs-1 postgresql localhost 6379 --verbose"

# Create symlinks to Zato components
ln -s /opt/zato/env/qs-1/load-balancer /etc/zato/components-enabled/load-balancer
ln -s /opt/zato/env/qs-1/server1 /etc/zato/components-enabled/server1
ln -s /opt/zato/env/qs-1/server2 /etc/zato/components-enabled/server2
ln -s /opt/zato/env/qs-1/web-admin /etc/zato/components-enabled/web-admin
