#!/bin/bash

# Specify Vagrant boxes to be installed on a localhost
declare -A BOXES
BOXES=(
        ["centos6-32"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.7-i386_chef-provisionerless.box"
        ["centos6-64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.7_chef-provisionerless.box"
        ["centos7-64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.1_chef-provisionerless.box"
        ["jessie64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_debian-7.8-i386_chef-provisionerless.box"
        ["precise32"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_debian-7.8_chef-provisionerless.box"
        ["precise64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_debian-8.1_chef-provisionerless.box"
        ["trusty32"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04-i386_chef-provisionerless.box"
        ["trusty64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"
        ["wheezy32"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04-i386_chef-provisionerless.box"
        ["wheezy64"]="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box"
        )

# Install the boxes on a localhost
for BOX in "${!BOXES[@]}"
do
    vagrant box add --name "$BOX" "${BOXES["$BOX"]}"
done
