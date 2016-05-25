#!/bin/bash -eux

echo "Creating zato database..."
sudo su - oracle -c "sqlplus / as sysdba @/u01/app/oracle/create_zato_db.sql"
