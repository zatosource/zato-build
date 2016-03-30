#!/bin/bash

# Install Apache with SSL support
yum -y install httpd mod_ssl

# Set up Apache
# Replace default ssl.conf with custom one
echo 'Overwriting default Apache SSL configuration file.'
cp -r /vagrant/files/ssl/ssl.conf /etc/httpd/conf.d/ssl.conf
echo 'Done.'

# First, prepare directory hosting a certificate and a key
sudo mkdir /etc/httpd/ssl

# Create a certificate and a key
echo "Generating key and certificate..."
sudo openssl req -x509 -nodes -days 3650 \
                 -subj "/C=EU/ST=Someland/L=Some City/O=Sample/CN=repo-box-centos" \
                 -newkey rsa:2048 \
                 -keyout /etc/httpd/ssl/repo-box-centos.key \
                 -out /etc/httpd/ssl/repo-box-centos.crt
echo "Done."
# Copy certificate for our test repo
if [ ! -f /etc/pki/tls/certs/repo-box-centos.crt ]
then
    cp -r /etc/httpd/ssl/repo-box-centos.crt /etc/pki/tls/certs
else
    echo 'Certificate has been set up already.'
fi

# Copy key for our test repo
if [ ! -f /etc/pki/tls/private/repo-box-centos.crt ] \
   && [ ! -f /etc/pki/tls/private/repo-box-centos.key ]
then
    cp -r /etc/httpd/ssl/repo-box-centos.crt \
          /etc/httpd/ssl/repo-box-centos.key \
          /etc/pki/tls/private
else
    echo 'Keys have been set up already.'
fi

# Restart the service
service httpd start

# Set Apache to be launched at startup
chkconfig httpd on
