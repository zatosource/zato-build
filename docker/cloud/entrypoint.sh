#!/bin/bash

env | grep _ >> /etc/environment
set -e

cd /opt/zato/ || exit 1
# touch /opt/zato/zato_user_password /opt/zato/change_zato_password && \

if [[ -z ${CLUSTER_NAME} ]]; then
    echo "CLUSTER_NAME can't be empty"
    exit 1
fi

if [[ -z ${SECRET_KEY} ]]; then
    echo "SECRET_KEY can't be empty"
    exit 1
fi

if [[ -z ${JWT_SECRET_KEY} ]]; then
    echo "JWT_SECRET_KEY can't be empty"
    exit 1
fi

if [[ -n "${REDIS_HOSTNAME}" ]]; then
    WAITS="${WAITS} -wait tcp://${REDIS_HOSTNAME}:6379 -timeout 10m "
else
    echo "REDIS_HOSTNAME can't be empty"
    exit 1
fi

if [[ -n "${VERBOSE}" && "${VERBOSE}" == "y" ]]; then
    OPTIONS=" --verbose "
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
    ODB_DATA="--odb_host ${ODB_HOSTNAME} --odb_port ${ODB_PORT} --odb_user ${ODB_USERNAME} --odb_db_name ${ODB_NAME} --odb_password ${ODB_PASSWORD}"
else
    echo "ODB_HOSTNAME can't be empty"
    exit 1
fi

if [[ ! -d /opt/zato/env/qs-1 ]];then
    mkdir -p /opt/zato/env/qs-1
    chown -R zato. /opt/zato/env/qs-1
fi

/usr/local/bin/dockerize ${WAITS}

if [[ "$ZATO_POSITION" != "load-balancer" ]]; then
    sleep 30
fi

gosu zato bash -c  "${ZATO_BIN} --version"
SERVER_NAME="$(hostname)"

case "$ZATO_POSITION" in
    "load-balancer" )
        [[ -n "${ZATO_ADMIN_INVOKE_PASSWORD}" ]] && ZATO_ADMIN_INVOKE_PASSWORD="--admin-invoke-password ${ZATO_ADMIN_INVOKE_PASSWORD}"

        echo "Checking ODB status"
        QUERY="\dt"
        if [[ -z "$(PGPASSWORD=${ODB_PASSWORD} psql --command="${QUERY}" --host=${ODB_HOSTNAME} --port=${ODB_PORT} --username=${ODB_USERNAME} ${ODB_NAME} |grep -v 'Did not find any relations'|grep ' | table | ')" ]]; then
            echo "${ZATO_BIN} create odb ${OPTIONS} ${ODB_DATA} ${ODB_TYPE}"
            gosu zato bash -c "${ZATO_BIN} create odb ${OPTIONS} ${ODB_DATA} ${ODB_TYPE}"
        else
            echo "ODB was created"
        fi

        echo "Cluster ODB status"
        QUERY="SELECT id FROM cluster WHERE name = '${CLUSTER_NAME}'"
        if [[ -n "$(PGPASSWORD=${ODB_PASSWORD} psql --command="${QUERY}" --host=${ODB_HOSTNAME} --port=${ODB_PORT} --username=${ODB_USERNAME} ${ODB_NAME} |grep '(0 rows)')" ]]; then
            echo "${ZATO_BIN} create cluster ${OPTIONS} ${ODB_DATA} ${ZATO_ADMIN_INVOKE_PASSWORD} ${ODB_TYPE} ${LB_HOSTNAME:-zato.localhost} ${LB_PORT:-11223} ${LB_AGENT_PORT:-20151} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME}"
            gosu zato bash -c "${ZATO_BIN} create cluster ${OPTIONS} ${ODB_DATA} ${ZATO_ADMIN_INVOKE_PASSWORD} ${ODB_TYPE} ${LB_HOSTNAME:-zato.localhost} ${LB_PORT:-11223} ${LB_AGENT_PORT:-20151} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME}"
        else
            echo "Cluster was created before"
        fi

        echo "${ZATO_BIN} create load_balancer ${OPTIONS} /opt/zato/env/qs-1/"
        gosu zato bash -c "${ZATO_BIN} create load_balancer ${OPTIONS} /opt/zato/env/qs-1/"

        sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/qs-1/config/repo/zato.config
    ;;
    "scheduler" )
        SECRET_KEY="--secret_key ${SECRET_KEY}"

        find /opt/zato/env/qs-1/
        echo "${ZATO_BIN} create scheduler ${OPTIONS} ${ODB_DATA} --kvdb_password '${REDIS_PASSWORD}' ${SECRET_KEY} /opt/zato/env/qs-1/ ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME}"
        gosu zato bash -c "${ZATO_BIN} create scheduler ${OPTIONS} ${ODB_DATA} --kvdb_password '${REDIS_PASSWORD}' ${SECRET_KEY} /opt/zato/env/qs-1/ ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME}"
        if [[ -n "${VERBOSE}" && "${VERBOSE}" == "y" ]]; then
            sed -i -e 's|INFO|DEBUG|' /opt/zato/env/qs-1/config/repo/logging.conf
        fi
    ;;
    "server" )
        SECRET_KEY="--secret_key ${SECRET_KEY}"
        JWT_SECRET_KEY="--jwt_secret ${JWT_SECRET_KEY}"

        echo "${ZATO_BIN} create server ${OPTIONS} ${ODB_DATA} --kvdb_password '${REDIS_PASSWORD}' ${JWT_SECRET_KEY} ${SECRET_KEY} --http_port 17010 /opt/zato/env/qs-1/ ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME} ${SERVER_NAME}"
        gosu zato bash -c "${ZATO_BIN} create server ${OPTIONS} ${ODB_DATA} --kvdb_password '${REDIS_PASSWORD}' ${JWT_SECRET_KEY} ${SECRET_KEY} --http_port 17010 /opt/zato/env/qs-1/ ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME} ${SERVER_NAME}"
        if [[ -n "${VERBOSE}" && "${VERBOSE}" == "y" ]]; then
            sed -i -e 's|INFO|DEBUG|' /opt/zato/env/qs-1/config/repo/logging.conf
        fi
        sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' /opt/zato/env/qs-1/config/repo/server.conf

        # If there is a file in the hot-deploy folder
        if [[ -n "$(find /opt/hot-deploy/ -type f)" ]]; then
            cat > /etc/supervisor/conf.d/zato_hotdeploy.conf <<-EOF
[program:hotdeploy]
command=/opt/zato/hotdeploy-utility.sh
directory=/opt/zato/
autorestart=unexpected
numprocs=1
EOF
        fi

        # If variable ZATO_ENMASSE_FILE is not empty
        if [[ -n "${ZATO_ENMASSE_FILE}" ]]; then
            cat > /etc/supervisor/conf.d/zato_enmasse.conf <<-EOF
[program:enmasse]
command=/opt/zato/enmasse-utility.sh
directory=/opt/zato/
autorestart=unexpected
numprocs=1
EOF
        fi

    ;;
    "webadmin" )
        [[ -n "${ZATO_ADMIN_INVOKE_PASSWORD}" ]] && ZATO_ADMIN_INVOKE_PASSWORD="--admin-invoke-password ${ZATO_ADMIN_INVOKE_PASSWORD}"
        echo "${ZATO_BIN} create web_admin ${OPTIONS} ${ODB_DATA} ${ZATO_ADMIN_INVOKE_PASSWORD} /opt/zato/env/qs-1/ ${ODB_TYPE}"
        gosu zato bash -c "${ZATO_BIN} create web_admin ${OPTIONS} ${ODB_DATA} ${ZATO_ADMIN_INVOKE_PASSWORD} /opt/zato/env/qs-1/ ${ODB_TYPE}"
        if [[ -n "${VERBOSE}" && "${VERBOSE}" == "y" ]]; then
            sed -i -e 's|INFO|DEBUG|' /opt/zato/env/qs-1/config/repo/logging.conf
        fi

        if [[ -n "${ZATO_WEB_ADMIN_PASSWORD}" ]]; then
            echo "Updating user admin's password"
            echo "${ZATO_BIN} update password ${OPTIONS} --password ${ZATO_WEB_ADMIN_PASSWORD} /opt/zato/env/qs-1/ ${TECH_ACCOUNT_NAME:-admin}"
            gosu zato bash -c "${ZATO_BIN} update password ${OPTIONS} --password ${ZATO_WEB_ADMIN_PASSWORD} /opt/zato/env/qs-1/ ${TECH_ACCOUNT_NAME:-admin}"
            echo "User admin's password updated"
        fi
    ;;
esac

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
