#!/bin/bash -eux

echo "Start the db..."
sudo su - oracle -c "sqlplus / as sysdba @/u01/app/oracle/startup.sql"
