#!/bin/bash

sudo su - oracle -c "sqlplus / as sysdba @/u01/app/oracle/create_srv_param_file.sql"
