#!/bin/bash

# Prepare the box and install Apache
yum -y check-update

# Python bindings are required (because of selinux)
yum -y install libselinux-python

# Random Number Generator is required to create enough entropy to create
# new test signing keys
yum -y install rng-tools

# Install createrepo to manage rpm repository
yum -y install createrepo

# Expect is crucial during package signing,
# because 'rpm' does not give any possibility
# of performing the process in an non-interactive way
yum -y install expect

# Start rng daemon
service rngd start
