#!/bin/bash

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
chwon -R jenkins:jenkins /opt/zato-build/ansible

# Install Ansible
apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible -y
apt-get update
apt-get install ansible -y
