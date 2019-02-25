#!/bin/bash

env | grep _ >> /etc/environment
set -e

cd /opt/zato/ || exit 1
# touch /opt/zato/zato_user_password /opt/zato/change_zato_password && \

if [[ -z "${ZATO_USER_PASSWORD}" ]]; then
  if [[ -f /opt/zato/zato_user_password ]];then
    echo "Reading the password for zato user from the file"
    ZATO_USER_PASSWORD="$(cat /opt/zato/zato_user_password)"
  else
    echo "Generating a password for zato user"
    ZATO_USER_PASSWORD="$(uuidgen)"
  fi
fi
if [[ -z "${ZATO_WEBADMIN_PASSWORD}" ]]; then
  if [[ -f /opt/zato/zato_user_password ]];then
    echo "Reading the password for web admin from the file"
    ZATO_WEBADMIN_PASSWORD="$(cat /opt/zato/web_admin_password)"
  else
    echo "Generating a password for web admin"
    ZATO_WEBADMIN_PASSWORD="$(uuidgen)"
  fi
fi

if [[ -n "${REDIS_HOSTNAME}" ]]; then
  WAITS="${WAITS} -wait tcp://${REDIS_HOSTNAME}:6379 -timeout 10m "
else
  REDIS_HOSTNAME=localhost
fi

if [[ -n "${ODB_HOSTNAME}" ]]; then
  if [[ -z "${ODB_TYPE}" && "${ODB_HOSTNAME}" == "postgres" ]]; then
    ODB_TYPE="postgresql"
    [[ -z "${ODB_PORT}" ]] && ODB_PORT=5432
    if [[ -z "${ODB_TYPE}" && ( "${ODB_HOSTNAME}" == "mysql" || "${ODB_HOSTNAME}" == "mariadb" ) ]]; then
      ODB_TYPE="mysql"
      [[ -z "${ODB_PORT}" ]] && ODB_PORT=3306
    fi
  fi
  WAITS="${WAITS} -wait tcp://${ODB_HOSTNAME}:${ODB_PORT} -timeout 10m "
  ODB_DATA="--odb_host '${ODB_HOSTNAME}' --odb_port '${ODB_PORT}' --odb_user '${ODB_USERNAME}' --odb_db_name '${ODB_NAME}' --odb_password '${ODB_PASSWORD}'"
else
  ODB_TYPE="sqlite"
fi

/usr/local/bin/dockerize ${WAITS} -template /opt/zato/supervisord.conf.template:/opt/zato/supervisord.conf

# Set a password for zato user
echo "${ZATO_USER_PASSWORD}" > /opt/zato/zato_user_password
chown zato:zato /opt/zato/zato_user_password && \
echo "zato:$(cat /opt/zato/zato_user_password)" > /opt/zato/change_zato_password && \
chpasswd < /opt/zato/change_zato_password

if [[ ! -d /opt/zato/env/qs-1 ]];then
  mkdir -p /opt/zato/env/qs-1
  chown zato. /opt/zato/env/qs-1
fi

su zato <<EOF
# Set a password for web admin and append it to a config file
echo "${ZATO_WEBADMIN_PASSWORD}" > /opt/zato/web_admin_password
echo 'password'=\$(cat /opt/zato/web_admin_password) >> /opt/zato/update_password.config
cd /opt/zato/env/qs-1 || exit 1
$ZATO_BIN quickstart create ${ODB_DATA} --kvdb_password '' /opt/zato/env/qs-1/ "${ODB_TYPE}" "${REDIS_HOSTNAME}" 6379
$ZATO_BIN from-config /opt/zato/update_password.config
sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/qs-1/load-balancer/config/repo/zato.config
sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server1/config/repo/server.conf
sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/server2/config/repo/server.conf
EOF

exec /usr/bin/supervisord -c /opt/zato/supervisord.conf
