#!/bin/bash

ANSIBLE_ROOT="$(dirname `pwd`)"

# Ansible playbook parameters
HOSTNAME=ubuntu-1404-64
RELEASE_VERSION=2.0.7
PACKAGE_VERSION=stable
DISTRIBUTION=ubuntu
SYSTEM=ubuntu-14.04-64
REPOSITORY=
TEST_SUITE=/opt/zato/development/tests/apitests

# Path to vagrant's user private key
PRIVATE_KEY="$ANSIBLE_ROOT"/vm/"$SYSTEM"/.vagrant/machines/default/virtualbox/private_key

BOX_NAME="trusty64"
BOX_URL="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box"

BOX_ON_LIST=`vagrant box list | grep "$BOX_NAME"`

if ! grep -q "$BOX_NAME" <<<"$BOX_ON_LIST"; then
    echo "Adding box "$BOX_NAME""
    vagrant box add "$BOX_NAME" "$BOX_URL"
else
    echo "The box "$BOX_NAME" is already installed. Skipping"
fi

cd "$ANSIBLE_ROOT"/vm/"$SYSTEM"

# Check for Vagrantfile, create a box if it doesn't exist,
# launch the box if it does exist:w
if [ -f "Vagrantfile" ]; then
    vagrant up
    STATUS="$?"
    if [ "$STATUS" == 0 ]; then
        while true
        do
            echo "There already is a Ubuntu box up and running..."
            echo "Do you want it to be destroyed and a new one build? [y/n]"
            read ANSWER
            case "$ANSWER" in
                y) echo "Destroying it and building a new one..."
                   cd "$ANSIBLE_ROOT"
                   echo "Removing the box..."
                   ansible-playbook -vvvv clean.yml
                   echo "Building a new box"
                   ansible-playbook -vvvv prepare_test_box.yml
                   break ;;

                n) echo "Proceeding without building a new box..."
                   break ;;

                *) continue ;;
            esac
        done
    fi
else
    echo "Building a new Ubuntu box..."
    cd "$ANSIBLE_ROOT"
    ansible-playbook -vvvv prepare_test_box.yml
fi

cd "$ANSIBLE_ROOT"
echo "Preparing Zato quickstart environment..."
ansible-playbook -vvvv apitests_prepare_zato.yml \
    --extra-vars "hostname=$HOSTNAME release_version=$RELEASE_VERSION
                  package_version=$PACKAGE_VERSION distribution=$DISTRIBUTION
                  repository=$REPOSITORY"

echo "Running API tests..."
ansible-playbook -vvvv apitests_run.yml \
    --extra-vars "hostname=$HOSTNAME test_suite=$TEST_SUITE"
