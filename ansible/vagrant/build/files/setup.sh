#!/bin/bash

# Setup root directories
SETUP_ROOT=/home/$USER/zato-build-test
ANSIBLE_ROOT=$SETUP_ROOT/zato-build/ansible/vagrant/build
JENKINS_ROOT=$SETUP_ROOT/jenkins

# Clone the repository containing Ansible playbooks
if [ ! -d $SETUP_ROOT/zato-build ]
then
    git clone https://github.com/zatosource/zato-build.git \
              $SETUP_ROOT/zato-build
fi

# Download Jenkins
mkdir -p $SETUP_ROOT/jenkins
if [ ! -f $SETUP_ROOT/jenkins/jenkins.war ]
then
    wget -O $SETUP_ROOT/jenkins/jenkins.war \
            http://mirrors.jenkins-ci.org/war/latest/jenkins.war
fi

# Prepare Vagrant - check for Vagrant boxes and install them
/vagrant/prepare_vagrant.sh

# Check Ansible installation
cd $ANSIBLE_ROOT
ansible-playbook test_setup.yml
