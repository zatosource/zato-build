#~/bin/bash

PARENT="$(dirname `pwd`)"
ANSIBLE_ROOT="$PARENT"/ansible/vagrant/build

# Ansible playbook parameters
HOSTNAME=ubuntu-1404-64
RELEASE_VERSION=2.0.7
PACKAGE_VERSION=stable
DISTRIBUTION=ubuntu
REPOSITORY=

BOX_NAME="trusty64"
BOX_URL="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"

BOX_ON_LIST=`vagrant box list | grep "$BOX"`

if [ "$BOX_ON_LIST" == "" ]
then
    echo "Adding box "$BOX_NAME""
    vagrant box add "$BOX_NAME" "$BOX_URL"
else
    echo "The box "$BOX_NAME" is already installed. Skipping"
fi

cd "$ANSIBLE_ROOT"
ansible-playbook prepare_test_box.yml

ansible-playbook apitests_prepare_zato.yml \
    --extra-vars "hostname=$HOSTNAME release_version=$RELEASE_VERSION
                  package_version=$PACKAGE_VERSION distribution=$DISTRIBUTION
                  repository=$REPOSITORY"
