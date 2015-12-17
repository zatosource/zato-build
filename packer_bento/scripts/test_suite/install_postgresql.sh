#!/bin/bash -eux

# Install PostgreSQL and a few other libraries
apt-get -y install postgresql-9.3 postgresql-server-dev-9.3 \
                   postgresql-contrib-9.3 python-psycopg2
