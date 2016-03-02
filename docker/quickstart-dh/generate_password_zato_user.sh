#!/bin/bash -eux

# Set a password for zato user
touch /opt/zato/zato_user_password /opt/zato/change_zato_password
uuidgen > /opt/zato/zato_user_password
chown zato:zato /opt/zato/zato_user_password
echo 'zato':$(cat /opt/zato/zato_user_password) > /opt/zato/change_zato_password
chpasswd < /opt/zato/change_zato_password
