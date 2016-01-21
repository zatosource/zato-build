#!/bin/bash -eux

# Upgrade box
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
