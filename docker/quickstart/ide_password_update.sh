#!/bin/bash
source /etc/environment

cd /opt/zato/env/qs-1 || exit 1

if [[ -n "${ZATO_IDE_PUBLISHER_PASSWORD}" ]]; then
    wget -q -O /opt/zato/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x /opt/zato/jq
    # Wait for server1 to start
    /usr/local/bin/dockerize -wait-http-status-code 200 -wait-retry-interval 10s -wait http://localhost:17010/zato/ping -timeout 10m

    echo "Updating ide_publisher password"
    user_id="$(curl -q "http://admin:$(cat ~/web_admin_password)@localhost:11223/zato/api/invoke/zato.security.basic-auth.get-list?cluster_id=1" 2>/dev/null | /opt/zato/jq '.[] | select(.username == "ide_publisher").id')"
    $ZATO_BIN service invoke --verbose --payload \
        "{\"password1\":\"${ZATO_IDE_PUBLISHER_PASSWORD}\", \"password2\": \"${ZATO_IDE_PUBLISHER_PASSWORD}\", \"id\": ${user_id}}" \
        /opt/zato/env/qs-1/server1/ zato.security.basic-auth.change-password || exit 1
fi
