#!/bin/bash

# Load the library of variables
. $PWD/vars.sh

# Install VirtualBox
echo 'deb http://download.virtualbox.org/virtualbox/debian xenial contrib' \
    >> /etc/apt//sources.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | \
    sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | \
    sudo apt-key add -
apt-get update
apt-get install virtualbox-$VB_VERSION -y

# Install Vagrant
wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb
dpkg -i vagrant_${VAGRANT_VERSION}_x86_64.deb

# Install Ansible
apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible -y
apt-get update
apt-get install ansible -y

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install jenkins -y

# Set up the jobs
mkdir $ZATO_BUILD_ROOT
cd $ZATO_BUILD_ROOT
git clone https://github.com/zatosource/zato-build.git .
git fetch origin jenkins
cd $ZATO_BUILD_ROOT/jenkins/ansible/jobs
git checkout origin/jenkins
cp -r ./* $JENKINS_ROOT/jobs/
chown -R jenkins:jenkins $JENKINS_ROOT/jobs/*
chown -R jenkins:jenkins $ANSIBLE_ROOT

# Download Vagrant boxes
for box in ${VAGRANT_BOXES[@]}
do
    vagrant box add $box --provider virtualbox
done

# Setup test repo boxes
for box in ${REPO_BOXES[@]}
do
    su - jenkins -c 'cd $ANSIBLE_ROOT/vm/$box && vagrant up && vagrant halt'
done

# Get jenkins-cli client
su - jenkins -c 'wget http://localhost:8080/jnlpJars/jenkins-cli.jar'
