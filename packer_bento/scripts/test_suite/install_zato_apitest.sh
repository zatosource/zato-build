#!/bin/bash -eux

# Install pip and zato-apitest dependencies
apt-get -y install libpq-dev libyaml-dev libxml2-dev libxslt1-dev \
                   python-dev python-pip

# Install zato-apitest
pip install zato-apitest
