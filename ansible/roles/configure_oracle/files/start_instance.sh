#!/bin/bash -eux

sudo su - oracle -c "sqlplus /nolog @/u01/app/oracle/create_zato_user.sql"
