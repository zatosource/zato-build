#!/bin/bash -eux

apt-get -y autoremove;
apt-get -y clean;

rm -f VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?;
