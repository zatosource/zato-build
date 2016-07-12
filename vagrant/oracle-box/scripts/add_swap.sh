#!/bin/bash -eux

dd if=/dev/zero of=/swapfile1 bs=2048 count=2097152
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1
swapon /swapfile1
echo "/swapfile1 swap swap defaults 0 0" >> /etc/fstab
