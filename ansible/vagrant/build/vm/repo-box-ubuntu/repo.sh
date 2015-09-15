#!/bin/bash

# Copy repo directories to the root directory
cp -r /vagrant/repo /var/www/

# Add Zato package signing key to the keyring
sudo gpg --allow-secret-key-import --import /vagrant/zato-repo-signing-key_sec.gpg

# Add a Zato package to the repository
sudo reprepro -Vb /var/www/repo/stable/2.0/ubuntu includedeb trusty /vagrant/zato-2.0.5-stable_amd64-trusty.deb
