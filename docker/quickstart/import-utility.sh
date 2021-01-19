#!/bin/bash
source /etc/environment

/usr/local/bin/dockerize -wait tcp://localhost:17010 -timeout 10m || exit 1

# add a new wait time
sleep 10

if [[ -d /opt/hot-deploy/ && -n "$(find /opt/hot-deploy/ -type f)" ]]; then
    find /opt/hot-deploy/ -type f -exec touch {} \;
fi

if [[ -n ${ZATO_ENMASSE_FILE} ]]; then
    # add a new wait time and check server access
    sleep ${ZATO_ENMASSE_SLEEP_TIME:-30}

    cd /opt/zato/env/qs-1 || exit 1
    [[ -z ${ZATO_SERVER_PATH} ]] && ZATO_SERVER_PATH="/opt/zato/env/qs-1/server1/"
    if [[ ! -f ${ZATO_SERVER_PATH}/config/repo/server.conf ]]; then
        echo "Zato server configuration not found at ${ZATO_SERVER_PATH}"
        exit 1
    fi

    if [[ -n "$(echo "${ZATO_ENMASSE_FILE}"|grep -Eo '(http|https)://[^/"]+')" ]];then
        echo "Downloading enmasse file from ${ZATO_ENMASSE_FILE}"
        TMPFILE="$(mktemp -d)"
        ZATO_ENMASSE_FILE_NAME=$(basename ${ZATO_ENMASSE_FILE})
        curl "${ZATO_ENMASSE_FILE}" > ${TMPFILE}/${ZATO_ENMASSE_FILE_NAME}
        ZATO_ENMASSE_FILE="${TMPFILE}/${ZATO_ENMASSE_FILE_NAME}"
    fi

    set -x # enable show commands
    if [[ -f ${ZATO_ENMASSE_FILE} ]]; then
        ${ZATO_BIN} enmasse ${ZATO_SERVER_PATH} --input ${ZATO_ENMASSE_FILE} --import --replace-odb-objects
    else
        echo "enmasse file ${ZATO_ENMASSE_FILE} not found"
        exit 1
    fi
    set +x # disable show commands
fi
