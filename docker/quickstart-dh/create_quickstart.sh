#!/bin/bash -eux

ZATO_ENV=/opt/zato/env/qs-1
ZATO_BIN=/opt/zato/current/bin/zato

su - zato -c "rm -rf $ZATO_ENV && mkdir -p $ZATO_ENV"
su - zato -c "$ZATO_BIN quickstart create $ZATO_ENV sqlite localhost 6379 --verbose --kvdb_password ''"
su - zato -c "sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' $ZATO_ENV/load-balancer/config/repo/zato.config"
su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' $ZATO_ENV/server1/config/repo/server.conf"
su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' $ZATO_ENV/server2/config/repo/server.conf"

# Set a password for zato user
echo "Setting up a password for zato user:"
touch /opt/zato/zato_user_password
touch /opt/zato/change_zato_password
uuidgen > /opt/zato/zato_user_password
chown zato:zato /opt/zato/zato_user_password
echo 'zato':$(cat /opt/zato/zato_user_password) > /opt/zato/change_zato_password
chpasswd < /opt/zato/change_zato_password

# Set a password for web admin and append it to a config file
echo "Setting up a password for web admin:"
touch /opt/zato/web_admin_password
chown zato:zato /opt/zato/web_admin_password
su - zato "uuidgen > /opt/zato/web_admin_password"
su - zato "echo 'password'=$(cat /opt/zato/web_admin_password) >> /opt/zato/update_password.config"
su - zato "$ZATO_BIN from-config /opt/zato/update_password.config"
