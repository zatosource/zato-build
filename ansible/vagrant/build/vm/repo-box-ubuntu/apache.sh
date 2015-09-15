#!/bin/bash

# Upgrade the box and install required apps
apt-get -y update
apt-get -y upgrade
apt-get -y install apache2 reprepro

# Copy our test repository configuration file
# to proper directory
cp -r /vagrant/repo.conf /etc/apache2/sites-available

# Disable the default Apache Virtual Host
sudo a2dissite 000-default

# Enable Apache SSL module
sudo a2enmod ssl

# Copy test key and certificate for our test repo
cp -r /vagrant/ssl /etc/apache2

# Enable test repo Virtual Host
sudo a2ensite repo

# Restart the service
sudo service apache2 restart
