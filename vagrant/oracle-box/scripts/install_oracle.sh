#!/bin/bash -eux

groupadd oinstall
groupadd dba
useradd oracle -g oinstall -G dba

cp /vagrant/files/sysctl.conf /etc/
chown root:root /etc/sysctl.conf
sysctl -p
sysctl -a

echo "oracle soft nproc 2047" >> /etc/security/limits.conf
echo "oracle hard nproc 16384" >> /etc/security/limits.conf
echo "oracle soft nofile 1024" >> /etc/security/limits.conf
echo "oracle hard nofile 65536" >> /etc/security/limits.conf

mkdir /stage/ /xe_logs/
cp /vagrant//files/oracle-xe-11.2.0-1.0.x86_64.rpm.zip /stage/
cp /vagrant/files/xe.rsp /stage/
touch /xe_logs/XEsilentinstall.log
chown -R oracle:oinstall /xe_logs/ /stage/

cd /stage/
unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip
rpm -ivh /stage/Disk1/oracle-xe-11.2.0-1.0.x86_64.rpm > /xe_logs/XEsilentinstall.log

su - oracle -c "/u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh"
su - oracle -c "echo '. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh' >> \
                .bashrc"
su - oracle -c "echo '. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh' >> \
                .bashprofile"

/etc/init.d/oracle-xe start
