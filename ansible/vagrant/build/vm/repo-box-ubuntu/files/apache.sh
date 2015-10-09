#!/bin/bash

# Upgrade the box and install Apache
apt-get -y update
apt-get -y upgrade
apt-get -y install apache2

# Prepare apache configuration file
if [ ! -f /etc/apache2/sites-available/repo.conf ]
then
    echo 'Copying apache configuration file.'
    cp -r /vagrant/files/repo.conf /etc/apache2/sites-available
    echo 'Done.'
else
    echo 'Configuration file already exists, not copying it.'
fi

# Disable the default Apache Virtual Host
if [ -f /etc/apache2/sites-enabled/000-default.conf ]
then
    echo 'Disabling Apache default site.'
    sudo a2dissite 000-default
else
    echo 'Apache default site already disabled. Skipping.'
fi

# Enable Apache SSL module
if [ ! -f /etc/apache2/mods-enabled/ssl.conf ] &&
   [ ! -f /etc/apache2/mods-enabled/ssl.load ]
then
    sudo a2enmod ssl
else
    echo 'Apache SSL module has been already enabled.'
fi

# Copy test key and certificate for our test repo
if [ ! -d /etc/apache2/ssl ]
then
    cp -r /vagrant/files/ssl /etc/apache2
else
    echo 'SSL keys have been set up already.'
fi

# Enable test repo Virtual Host
if [ ! -f /etc/apache2/sites-enabled/repo.conf ]
then
    sudo a2ensite repo
else
    echo 'Repo site has been already enabled.'
fi

# Restart the service
sudo service apache2 restart
