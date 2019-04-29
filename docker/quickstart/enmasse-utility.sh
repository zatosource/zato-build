#!/bin/bash
source /etc/environment

/usr/local/bin/dockerize -wait tcp://localhost:17010 -timeout 10m

# add a new wait time
sleep 5

cd /opt/zato/env/qs-1 || exit 1
[[ -z ${ZATO_SERVER_PATH} ]] && ZATO_SERVER_PATH="/opt/zato/env/qs-1/server1/"
if [[ ! -d ${ZATO_SERVER_PATH} ]]; then
    echo "Zato server path at ${ZATO_SERVER_PATH} doesn't exists"
    exit 1
fi
set -x # enable show commands
if [[ -f ${ZATO_ENMASSE_FILE} ]]; then
    ${ZATO_BIN} enmasse ${ZATO_SERVER_PATH} --input ${ZATO_ENMASSE_FILE} --import --replace-odb-objects
else
    echo "enmasse file ${ZATO_ENMASSE_FILE} not found"
    exit 1
fi
set +x # disable show commands
