#!/bin/bash

ZATO_BUILD_ROOT=/opt/zato-build
ANSIBLE_ROOT=$ZATO_BUILD_ROOT/ansible
JENKINS_ROOT=/var/lib/jenkins
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
VAGRANT_BOXES=(
    bento/centos-6.7
    bento/centos-6.7-i386
    bento/debian-7.8
    bento/debian-7.8-i386
    bento/debian-7.9
    bento/debian-7.9-i386
    bento/debian-8.4
    bento/debian-8.4-i386
    bento/ubuntu-12.04
    bento/ubuntu-12.04-i386
    bento/ubuntu-14.04
    bento/ubuntu-14.04-i386
    bento/ubuntu-16.04
    bento/ubuntu-16.04-i386
)

for box in ${VAGRANT_BOXES[@]}
do
    vagrant box add $box --provider virtualbox
done

# Setup test repo boxes
REPO_BOXES=( repo-box-ubuntu repo-box-centos )
for box in ${REPO_BOXES[@]}
do
    su - jenkins -c "cd $ANSIBLE_ROOT/vm/$box && vagrant up && vagrant halt"
done
