#!/bin/bash

git clone https://github.com/zatosource/zato-build.git
cd ./zato-build
git fetch origin u/ddmx
git checkout u/ddmx
cd ansible
ansible-playbook -i environments/ddmx d_create_initial_env.yml \
    --extra-vars "odb_type=postgresql"
