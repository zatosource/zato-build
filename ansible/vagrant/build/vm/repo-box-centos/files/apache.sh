#!/bin/bash

# Upgrade the box and install Apache
yum -y check-update
yum -y update
yum -y install httpd mod_ssl

# Prepare repo directory structure
if [ ! -f /var/www/repo ]
then
    echo 'Creating repo directory structure'
    cp -r /vagrant/files/repo /var/www
else
    echo 'Directory structure is already there.'
fi

# Replace default ssl.conf with custom one
echo 'Overwriting default Apache SSL configuration file.'
cp -r /vagrant/files/ssl/ssl.conf /etc/httpd/conf.d/ssl.conf
echo 'Done.'

# Copy certificate for our test repo
if [ ! -f /etc/pki/tls/certs/ca.crt ]
then
    cp -r /vagrant/files/ssl/ca.crt /etc/pki/tls/certs
else
    echo 'Certificate has been set up already.'
fi

# Copy key for our test repo
if [ ! -f /etc/pki/tls/private/ca.csr ] \
   && [ ! -f /etc/pki/tls/private/ca.key ]
then
    cp -r /vagrant/files/ssl/ca.csr \
          /vagrant/files/ssl/ca.key \
          /etc/pki/tls/private
else
    echo 'Keys have been set up already.'
fi

# Restart the service
service httpd start
