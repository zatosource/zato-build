#!/bin/bash
source /etc/environment

exec &> /opt/zato/ide_publisher_update.log

user_id=""

function get_user_id() {
    # Wait for server1 to start
    /usr/local/bin/dockerize -wait-http-status-code 200 -wait-retry-interval 5s -wait http://localhost:17010/zato/ping -timeout 10m

    echo "get ide_publisher id"
    user_id="$(curl -q "http://admin:$(cat /opt/zato/web_admin_password)@localhost:17010/zato/api/invoke/zato.security.basic-auth.get-list?cluster_id=1" 2>/dev/null | /opt/zato/jq '.[] | select(.username == "ide_publisher").id')"
}

function make_update() {
    # Wait for server1 to start
    /usr/local/bin/dockerize -wait-http-status-code 200 -wait-retry-interval 5s -wait http://localhost:17010/zato/ping -timeout 10m

    echo "update ide_publisher password"
    $ZATO_BIN service invoke --verbose --payload \
        "{\"password1\":\"${ZATO_IDE_PUBLISHER_PASSWORD}\", \"password2\": \"${ZATO_IDE_PUBLISHER_PASSWORD}\", \"id\": ${user_id}}" \
        /opt/zato/env/qs-1/server1/ zato.security.basic-auth.change-password
}

cd /opt/zato/env/qs-1 || exit 1
if [[ -n "${ZATO_IDE_PUBLISHER_PASSWORD}" ]]; then
    if [[ ! -x /opt/zato/jq  ]]; then
        wget -q -O /opt/zato/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x /opt/zato/jq
    fi

    # run until no error
    until get_user_id
    do
        sleep 2
        echo "Retrying"
    done

    # run until no error
    until make_update
    do
        sleep 2
        echo "Retrying"
    done
fi
