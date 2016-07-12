#!/bin/bash -eux

echo "Creating zato user..."
sudo su - oracle -c "sqlplus / as sysdba @/u01/app/oracle/create_zato_user.sql"
