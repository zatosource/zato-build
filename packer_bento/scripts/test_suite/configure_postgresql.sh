#!/bin/bash -eux

sed -i 's/ peer/ trust/g' /etc/postgresql/9.3/main/pg_hba.conf

service postgresql restart
sleep 20

# Prepare database for Zato
psql -U postgres -c "CREATE ROLE zato WITH NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'zato'"
psql -U postgres -c "CREATE DATABASE zato WITH OWNER zato"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE zato to zato"
