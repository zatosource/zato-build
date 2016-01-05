#!/bin/bash -eux

# Create and run quickstart environment
su - zato -c "mkdir -p /opt/zato/env/qs-1"

su - zato -c "/opt/zato/current/bin/zato quickstart create /opt/zato/env/qs-1 postgresql localhost 6379 --odb_host localhost --odb_port 5432 --odb_user zato --odb_db_name zato --odb_password zato --postgresql_schema zato --kvdb_password '' --cluster_name pahcluster --servers 2 --verbose"

# Create symlinks to Zato components
ln -s /opt/zato/env/qs-1/load-balancer \
      /etc/zato/components-enabled/load-balancer
ln -s /opt/zato/env/qs-1/server1 \
      /etc/zato/components-enabled/server1
ln -s /opt/zato/env/qs-1/server2 \
      /etc/zato/components-enabled/server2
ln -s /opt/zato/env/qs-1/web-admin \
      /etc/zato/components-enabled/web-admin
