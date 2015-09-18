#!/bin/bash

# Create Zato test repository
echo 'Creating a repository...'
sudo -u aptly aptly repo create -config="/opt/aptly/.aptly.conf" zato-repo
