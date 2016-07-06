#!/bin/bash -eux

sudo su - oracle -c "sqlplus / as system @/u01/app/oracle/set_access.sql"
