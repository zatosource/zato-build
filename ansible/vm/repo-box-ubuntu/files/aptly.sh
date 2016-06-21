#!/bin/bash

# Install Aptly and configure it
cp /vagrant/files/aptly.list /etc/apt/sources.list.d

apt-key adv --keyserver keys.gnupg.net --recv-keys 9E3E53F19C7DE460

apt-get update
apt-get -y install aptly

# Create 'aptly' group and user
if ! getent group aptly >/dev/null; then
    addgroup aptly
fi
if ! getent passwd zato >/dev/null; then
    adduser --ingroup aptly --home /opt/aptly --shell /bin/bash \
            --gecos "Maintainer of Zato repository" --disabled-password aptly
fi

# Prepare aptly configuration file
if [ ! -f /opt/aptly/.aptly.conf ]
then
    echo 'Copying aptly configuration file.'
    cp /vagrant/files/.aptly.conf /opt/aptly/
    chown aptly:aptly /opt/aptly/.aptly.conf
    echo 'Done.'
else
    echo 'Configuration file already exists, not copying it.'
fi

# Create incoming directory to store copied Zato packages
mkdir -p /opt/aptly/incoming/ubuntu/precise /opt/aptly/incoming/ubuntu/trusty \
         /opt/aptly/incoming/debian/xenial /opt/aptly/incoming/debian/wheezy \
         /opt/aptly/incoming/debian/jessie
chown -R aptly:aptly /opt/aptly/incoming
