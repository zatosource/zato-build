#!/bin/bash

echo "Creating an initial Zato distributed environment..."
sleep 1
cd ./zato-build/ansible
ansible-playbook -i environments/ddmx d_create_initial_env.yml \
    --extra-vars "odb_type=postgresql"
