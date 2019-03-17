#!/bin/bash

for f in Vagrantfile ansible.cfg provisioning/setup.yml provisioning/requirements.yml provisioning/main.yml provisioning/files/provisioning/supervisord.conf;do
    [[ -d "$(dirname $f)" ]] || mkdir -p "$(dirname $f)"
    wget -nc -O $f https://raw.githubusercontent.com/zatosource/zato-build/master/vagrant/zato-3.0/$f
done

echo "All files downloaded."
echo ""
echo "You can run 'vagrant up' to run Zato's quickstart in Vagrant."
echo ""
