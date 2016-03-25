#!/bin/bash

# This tool is used to generate enough of entropy to create gpg keys
sudo apt-get install rng-tools

# Create Zato test repository
distributions=( wheezy jessie precise trusty )

echo 'Creating repositories...'

for distribution in "${distributions[@]}"
do
    sudo -u aptly -H aptly repo create -distribution=$distribution zato-stable-$distribution
done

echo 'Done.'

# Create repo root directory
if [ ! -d /var/www/repo ]
then
    sudo mkdir -p /var/www/repo/stable/2.0/
else
    echo 'Repo directory already exists, not creating it.'
fi

# Copy gpg key config file
cp /vagrant/files/key_config /opt/aptly/
chown aptly:aptly /opt/aptly/key_config

# Generate Zato package signing test keys
sudo -u aptly -H gpg --batch --gen-key /opt/aptly/key_config

# Copy public test Zato package signing key
if [ ! -f /var/www/repo/zato-deb-test.pub ]
then
    sudo cp /opt/aptly/zato-deb-test.pub /var/www/repo
else
    echo 'Zato repository test key already in place.'
fi

# Add private test Zato package signing key to the keyring
sudo -u aptly -H gpg --allow-secret-key-import --import /opt/aptly/zato-deb-test.sec
