#!/bin/bash

# Setup working directory
SETUP_ROOT=/home/$USER/zato-build-test
mkdir -p $SETUP_ROOT/jenkins

# Clone the repository containing Ansible playbooks
if [ ! -d $SETUP_ROOT/zato-build ]
then
    git clone https://github.com/zatosource/zato-build.git \
              $SETUP_ROOT/zato-build
fi

# Download Jenkins
if [ ! -f $SETUP_ROOT/jenkins/jenkins.war ]
then
    wget -O $SETUP_ROOT/jenkins/jenkins.war \
            http://mirrors.jenkins-ci.org/war/latest/jenkins.war
fi
