#!/bin/bash

echo "Cloning zato-build repository..."
sleep 1
git clone https://github.com/zatosource/zato-build.git
echo ""
sleep 1

echo "Switching to u/ddmx branch..."
sleep 1
cd ./zato-build
git fetch origin u/ddmx
git checkout u/ddmx
echo ""
sleep 1

echo "Creating an initial Zato distributed environment..."
sleep 1
cd ansible
ansible-playbook -i environments/ddmx d_create_initial_env.yml \
    --extra-vars "odb_type=postgresql"
