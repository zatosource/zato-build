#!/bin/bash -eux

sudo su - oracle -c "sqlplus / as sysdba @/u01/app/oracle/set_access.sql"
