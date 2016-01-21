#!/bin/bash -eux

# Install helper programs
apt-get -y install apt-transport-https python-software-properties \
                   software-properties-common \
                   curl

# Add the package signing key
curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | apt-key add -

# Add Zato repo and update sources
apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
apt-get update

# Install Zato
apt-get -y install zato

# Set ownership of 'current' symlink to zato
chown -h zato:zato /opt/zato/current
