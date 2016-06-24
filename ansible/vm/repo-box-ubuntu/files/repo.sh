#!/bin/bash

# This tool is used to generate enough of entropy to create gpg keys
sudo apt-get install rng-tools

# Create Zato test repository
distributions=( wheezy jessie precise trusty xenial )

echo 'Creating repositories...'

for distribution in "${distributions[@]}"
do
    sudo su - aptly -c "aptly repo create -distribution=$distribution \
        zato-stable-$distribution"
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
sudo cp /vagrant/files/key_config /opt/aptly/
sudo chown aptly:aptly /opt/aptly/key_config

# Generate Zato package signing test keys
sudo su - aptly -c "gpg --batch --gen-key /opt/aptly/key_config"

# Export the public key
sudo su - aptly -c "gpg --armor --export example@example.com > \
    /opt/aptly/zato-deb-test.pgp.asc"

# Copy public test Zato package signing key
if [ ! -f /var/www/repo/zato-deb-test.pgp.asc ]
then
    sudo cp /opt/aptly/zato-deb-test.pgp.asc /var/www/repo
else
    echo 'Zato repository test key already in place.'
fi
