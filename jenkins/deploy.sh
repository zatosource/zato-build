#!/bin/bash

VAGRANT_VERSION=1.8.6
VB_VERSION=5.1

# Install VirtualBox
echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" \
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
cd /opt/
git clone https://github.com/zatosource/zato-build.git
cd /opt/zato-build
git fetch origin jenkins
cd /opt/zato-build/jenkins/ansible/jobs
git checkout origin/jenkins
cp -r ./* /var/lib/jenkins/jobs/
chown -R jenkins:jenkins /var/lib/jenkins/jobs/*
chown -R jenkins:jenkins /opt/zato-build/ansible
