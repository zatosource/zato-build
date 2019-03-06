#!/bin/bash

env | grep _ >> /etc/environment
set -e

cd /opt/zato/ || exit 1
# touch /opt/zato/zato_user_password /opt/zato/change_zato_password && \

if [[ -z "${ZATO_SSH_PASSWORD}" ]]; then
  if [[ -f /opt/zato/zato_user_password ]];then
    echo "Reading the password for zato user from the file"
    ZATO_SSH_PASSWORD="$(cat /opt/zato/zato_user_password)"
  else
    echo "Generating a password for zato user"
    ZATO_SSH_PASSWORD="$(uuidgen)"
  fi
fi
if [[ -z "${ZATO_WEB_ADMIN_PASSWORD}" ]]; then
  if [[ -f /opt/zato/zato_user_password ]];then
    echo "Reading the password for web admin from the file"
    ZATO_WEBADMIN_PASSWORD="$(cat /opt/zato/web_admin_password)"
  else
    echo "Generating a password for web admin"
    ZATO_WEBADMIN_PASSWORD="$(uuidgen)"
    su zato <<EOF
# Set a password for web admin and append it to a config file
echo "${ZATO_WEBADMIN_PASSWORD}" > /opt/zato/web_admin_password
echo "password=${ZATO_WEBADMIN_PASSWORD}" >> /opt/zato/update_password.config
EOF
  fi
fi

if [[ -n "${REDIS_HOSTNAME}" ]]; then
  WAITS="${WAITS} -wait tcp://${REDIS_HOSTNAME}:6379 -timeout 10m "
else
  export REDIS_HOSTNAME="localhost"
  echo "REDIS_HOSTNAME=\"${REDIS_HOSTNAME}\"" >> /etc/environment
fi

if [[ -n "${ODB_HOSTNAME}" ]]; then
  if [[ -z "${ODB_TYPE}" && "${ODB_HOSTNAME}" == "postgres" ]]; then
    ODB_TYPE="postgresql"
    [[ -z "${ODB_PORT}" ]] && ODB_PORT=5432
    if [[ -z "${ODB_TYPE}" && ( "${ODB_HOSTNAME}" == "mysql" || "${ODB_HOSTNAME}" == "mariadb" ) ]]; then
      ODB_TYPE="mysql"
      [[ -z "${ODB_PORT}" ]] && ODB_PORT=3306
    fi
    echo "ODB_TYPE=\"${ODB_TYPE}\"" >> /etc/environment
  fi
  WAITS="${WAITS} -wait tcp://${ODB_HOSTNAME}:${ODB_PORT} -timeout 10m "
  echo "ODB_DATA=\"--odb_host ${ODB_HOSTNAME} --odb_port ${ODB_PORT} --odb_user ${ODB_USERNAME} --odb_db_name ${ODB_NAME} --odb_password ${ODB_PASSWORD}\"" >> /etc/environment
else
  export ODB_TYPE="postgresql"
  export ODB_PORT="5432"
  export ODB_HOSTNAME="localhost"
  [[ -z "${ODB_USERNAME}" ]] && ODB_USERNAME="postgres"
  [[ -z "${ODB_PASSWORD}" ]] && ODB_PASSWORD=""$(uuidgen)""
  echo "ODB_TYPE=\"${ODB_TYPE}\"" >> /etc/environment
  echo "ODB_DATA=\"--odb_host ${ODB_HOSTNAME:-localhost} --odb_port ${ODB_PORT:-5432} --odb_user ${ODB_USERNAME:-postgres} --odb_db_name ${ODB_NAME:-zato} --odb_password ${ODB_PASSWORD}\"" >> /etc/environment
fi

/usr/local/bin/dockerize ${WAITS} -template /opt/zato/supervisord.conf.template:/opt/zato/supervisord.conf

# Set a password for zato user
echo "${ZATO_SSH_PASSWORD}" > /opt/zato/zato_user_password && \
chown zato:zato /opt/zato/zato_user_password && \
echo "zato:$(cat /opt/zato/zato_user_password)" > /opt/zato/change_zato_password && \
chpasswd < /opt/zato/change_zato_password

if [[ ! -d /opt/zato/env/qs-1 ]];then
  mkdir -p /opt/zato/env/qs-1
  chown zato. /opt/zato/env/qs-1
fi

# quickstart-bootstrap
if [[ "${ODB_TYPE}" == "postgresql" && "${ODB_HOSTNAME}" == "localhost" ]]; then
  echo "Initializing Postgresql database"
  export PGPASSWORD="${ODB_PASSWORD}"
  su postgres -c "$PGBINPATH/initdb --username=\"${ODB_USERNAME:-postgres}\" --pwfile=<(echo \"$ODB_PASSWORD\") -D \"$PGDATA\";PGUSER=\"${PGUSER:-$POSTGRES_USER}\" $PGBINPATH/pg_ctl -D \"$PGDATA\" -o \"-c listen_addresses='127.0.0.1'\"  -w start"
  psql=( psql -v ON_ERROR_STOP=1 --username "${ODB_USERNAME:-postgres}" --no-password )
  "${psql[@]}" --dbname postgres --set db="${ODB_NAME:-zato}" <<-'EOSQL'
CREATE DATABASE :"db" ;
EOSQL
  psql+=( --dbname "$POSTGRES_DB" )
  # create wait instruction for internal postgresql
  WAITS="${WAITS} -wait tcp://localhost:5432 -timeout 10m "
fi
# wait for ODB again
/usr/local/bin/dockerize ${WAITS}
echo "Running quickstart-bootstrap"
sudo -H -u zato /opt/zato/quickstart-bootstrap.sh
if [[ "${ODB_TYPE}" == "postgresql" && "${ODB_HOSTNAME}" == "localhost" ]]; then
  echo "Stopping initialization of Postgresql"
  su postgres -c "PGUSER=\"${PGUSER:-$POSTGRES_USER}\" $PGBINPATH/pg_ctl -D "$PGDATA" -m fast -w stop"
	unset PGPASSWORD
fi

exec /usr/bin/supervisord -c /opt/zato/supervisord.conf
