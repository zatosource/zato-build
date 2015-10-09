#!/bin/bash

# Upgrade the box and install Apache
yum -y check-update
yum -y update
yum -y install httpd mod_ssl
service httpd start

# Prepare apache configuration file
if [ ! -f /etc/httpd/conf.d/repo.conf ]
then
    echo 'Copying apache configuration file.'
    cp -r /vagrant/files/repo.conf /etc/httpd/conf.d
    echo 'Done.'
else
    echo 'Configuration file already exists, not copying it.'
fi

cp /vagrant/files/repo.conf /etc/httpd/conf.d/ssl.conf

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
service httpd reload
