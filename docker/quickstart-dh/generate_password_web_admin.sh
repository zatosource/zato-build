#!/bin/bash -eux

# Set a password for web admin and append it to a config file
touch /opt/zato/web_admin_password
uuidgen > /opt/zato/web_admin_password
echo 'password'=$(cat /opt/zato/web_admin_password) >> /opt/zato/update_password.config
/opt/zato/current/bin/zato from-config /opt/zato/update_password.config
