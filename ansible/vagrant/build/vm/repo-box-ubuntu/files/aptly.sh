#!/bin/bash

# Install Aptly and configure it
cp /vagrant/files/aptly.list /etc/apt/sources.list.d

apt-key adv --keyserver keys.gnupg.net --recv-keys E083A3782A194991

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
