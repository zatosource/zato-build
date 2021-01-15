#!/bin/bash

for f in ansible.cfg \
    Vagrantfile \
    provisioning/main.yml \
    provisioning/setup.yml \
    provisioning/requirements.yml \
    provisioning/files/provisioning/supervisord.conf \
    provisioning/roles/.gitkeep
do
    [[ -n "$(dirname $f)" && -d "$(dirname $f)" ]] || mkdir -p "$(dirname $f)"
    curl "https://raw.githubusercontent.com/zatosource/zato-build/master/vagrant/zato-3.2/$f" > "${f}"
done