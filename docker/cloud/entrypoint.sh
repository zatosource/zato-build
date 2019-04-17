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

#
# # Set a password for zato user
# echo "${ZATO_SSH_PASSWORD}" > /opt/zato/zato_user_password && \
#     chown zato:zato /opt/zato/zato_user_password && \
#     echo "zato:$(cat /opt/zato/zato_user_password)" > /opt/zato/change_zato_password && \
#     chpasswd < /opt/zato/change_zato_password

if [[ ! -d /opt/zato/env/qs-1 ]];then
    mkdir -p /opt/zato/env/qs-1
    chown zato. /opt/zato/env/qs-1
fi

/usr/local/bin/dockerize ${WAITS}

if [[ "$ZATO_POSITION" != "load-balancer" ]]; then
    sleep 30
fi

gosu zato bash -c  "${ZATO_BIN} --version"

case "$ZATO_POSITION" in
    "load-balancer" )
        if [[ -z ${REDIS_HOSTNAME} ]]; then
            echo "REDIS_HOSTNAME not defined"
            exit 1
        fi
        gosu zato bash -c "${ZATO_BIN} create odb ${ODB_DATA} ${ODB_TYPE}"
        [[ -n "${ZATO_WEB_ADMIN_PASSWORD}" ]] && ZATO_WEB_ADMIN_PASSWORD="--tech_account_password ${ZATO_WEB_ADMIN_PASSWORD}"
        gosu zato bash -c "${ZATO_BIN} create cluster ${ODB_DATA} ${ZATO_WEB_ADMIN_PASSWORD} ${ODB_TYPE} ${LB_HOST:-zato.localhost} ${LB_PORT:-11223} ${LB_AGENT_PORT:-20151} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME} ${TECH_ACCOUNT_NAME:-admin}"
        gosu zato bash -c "${ZATO_BIN} create load_balancer /opt/zato/env/qs-1/load-balancer"
        export ZATO_SERVICE="${ZATO_BIN} start /opt/zato/env/qs-1/load-balancer --fg"
    ;;
    "scheduler" )
        if [[ -z ${REDIS_HOSTNAME} ]]; then
            echo "REDIS_HOSTNAME not defined"
            exit 1
        fi

        [[ -n "${SECRET_KEY}" ]] && SECRET_KEY="--secret_key ${SECRET_KEY}"

        gosu zato bash -c "${ZATO_BIN} create scheduler ${ODB_DATA} ${SECRET_KEY} /opt/zato/env/qs-1/scheduler ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME}"

        export ZATO_SERVICE="${ZATO_BIN} start /opt/zato/env/qs-1/scheduler --fg"
    ;;
    "server" )
        if [[ -z ${REDIS_HOSTNAME} ]]; then
            echo "REDIS_HOSTNAME not defined"
            exit 1
        fi

        [[ -n "${JWT_SECRET_KEY}" ]] && JWT_SECRET_KEY="--jwt_secret ${JWT_SECRET_KEY}"
        [[ -n "${SECRET_KEY}" ]] && SECRET_KEY="--secret_key ${SECRET_KEY}"

        gosu zato bash -c "${ZATO_BIN} create server ${ODB_DATA} ${JWT_SECRET_KEY} ${SECRET_KEY} --http_port 17010 /opt/zato/env/qs-1/server ${ODB_TYPE} ${REDIS_HOSTNAME} ${REDIS_PORT:-6379} ${CLUSTER_NAME} ${SERVER_NAME}"

        export ZATO_SERVICE="${ZATO_BIN} start /opt/zato/env/qs-1/server --fg"
    ;;
    "webadmin" )
        [[ -n "${ZATO_WEB_ADMIN_PASSWORD}" ]] && ZATO_WEB_ADMIN_PASSWORD="--tech_account_password ${ZATO_WEB_ADMIN_PASSWORD}"
        gosu zato bash -c "${ZATO_BIN} create web_admin ${ODB_DATA} ${ZATO_WEB_ADMIN_PASSWORD} /opt/zato/env/qs-1/webadmin ${ODB_TYPE} ${TECH_ACCOUNT_NAME:-admin}"
        export ZATO_SERVICE="${ZATO_BIN} start /opt/zato/env/qs-1/webadmin --fg"
    ;;
esac

exec gosu zato bash -c "$ZATO_SERVICE"
