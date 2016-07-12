#!/bin/bash -eux

/etc/init.d/oracle-xe configure responseFile=/stage/xe.rsp

sudo su - oracle -c "sqlplus / as sysdba @/vagrant/files/create_zato_user.sql"
sudo su - oracle -c "sqlplus / as sysdba @/vagrant/files/set_access.sql"
