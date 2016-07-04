#!/bin/bash -eux

# Create and run quickstart environment
sudo su - zato -c "mkdir -p /opt/zato/env/qs-1"
sudo su - zato \
    -c "/opt/zato/current/bin/zato quickstart create /opt/zato/env/qs-1 sqlite localhost 6379 --kvdb_password '' --verbose"

# Create symlinks to Zato components
ln -s /opt/zato/env/qs-1/load-balancer /etc/zato/components-enabled/load-balancer
ln -s /opt/zato/env/qs-1/server1 /etc/zato/components-enabled/server1
ln -s /opt/zato/env/qs-1/server2 /etc/zato/components-enabled/server2
ln -s /opt/zato/env/qs-1/web-admin /etc/zato/components-enabled/web-admin

# Set a web-admin password
touch /opt/zato/web-admin-password
touch /opt/zato/update-password.config
uuidgen > /opt/zato/web-admin-password
echo '# Zato update password
command=update_password
path=/opt/zato/env/qs-1/web-admin
store_config=True
username=admin' >> /opt/zato/update-password.config
echo 'password'=$(cat /opt/zato/web-admin-password) >> /opt/zato/update-password.config
cd /opt/zato
sudo su - zato -c "zato from-config /opt/zato/update-password.config"
