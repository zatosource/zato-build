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
