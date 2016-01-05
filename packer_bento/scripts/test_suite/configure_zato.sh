#!/bin/bash -eux

su - zato -c "sed -i 's/bind 127.0.0.1:11223/bind 0.0.0.0:11223/' \
              /opt/zato/env/qs-1/load-balancer/config/repo/zato.config"

su - zato -c "sed -i 's/gunicorn_bind=localhost:17010/gunicorn_bind=0.0.0.0:17010/' \
              /opt/zato/env/qs-1/server1/config/repo/server.conf"
su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/' \
              /opt/zato/env/qs-1/server1/config/repo/server.conf"

su - zato -c "sed -i 's/gunicorn_bind=localhost:17011/gunicorn_bind=0.0.0.0:17011/' \
              /opt/zato/env/qs-1/server2/config/repo/server.conf"
su - zato -c "sed -i 's/gunicorn_workers=2/gunicorn_workers=1/' \
              /opt/zato/env/qs-1/server2/config/repo/server.conf"
