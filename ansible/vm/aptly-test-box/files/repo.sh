#!/bin/bash

# Create Zato test repository
distributions=( wheezy jessie precise trusty )


echo 'Creating repositories...'

for distribution in "${distributions[@]}"
do
    sudo -u aptly -H aptly repo create -distribution=$distribution zato-stable-$distribution
done

echo 'Done.'

# Create repo directory
if [ ! -d /var/www/repo ]
then
    sudo mkdir -p /var/www/repo/stable/2.0
else
    echo 'Repo directory already exists, not creating it.'
fi

# Copy public test Zato package signing key
if [ ! -f /var/www/repo/zato-deb_pub.gpg ]
then
    sudo cp /vagrant/files/keys/zato-deb_pub.gpg /var/www/repo
else
    echo 'Zato repository test key already in place.'
fi

# Add private test Zato package signing key to the keyring
sudo -u aptly -H gpg --allow-secret-key-import --import /vagrant/files/keys/zato-deb_sec.gpg
