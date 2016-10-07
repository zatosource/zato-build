#!/bin/bash

ZATO_BUILD_ROOT=/opt/zato-build
ANSIBLE_ROOT=$ZATO_BUILD_ROOT/ansible
JENKINS_ROOT=/var/lib/jenkins
VAGRANT_VERSION=1.8.6
VB_VERSION=5.1

#VAGRANT_BOXES=(
#    bento/centos-6.7
#    bento/centos-6.7-i386
#    bento/debian-7.8
#    bento/debian-7.8-i386
#    bento/debian-7.9
#    bento/debian-7.9-i386
#    bento/debian-8.4
#    bento/debian-8.4-i386
#    bento/ubuntu-12.04
#    bento/ubuntu-12.04-i386
#    bento/ubuntu-14.04
#    bento/ubuntu-14.04-i386
#    bento/ubuntu-16.04
#    bento/ubuntu-16.04-i386
#)
VAGRANT_BOXES=(
    bento/debian-8.4
)

REPO_BOXES=( repo-box-ubuntu repo-box-centos )

JENKINS_CLI_PREFIX='java -jar jenkins-cli.jar -s http://localhost:8080/'

JENKINS_PLUGINS=(
    http://updates.jenkins-ci.org/latest/conditional-buildstep.hpi
    http://updates.jenkins-ci.org/latest/email-ext.hpi
    http://updates.jenkins-ci.org/latest/envinject.hpi
    http://updates.jenkins-ci.org/latest/ldap.hpi
    http://updates.jenkins-ci.org/latest/run-condition.hpi
    http://updates.jenkins-ci.org/latest/run-condition-extras.hpi
    http://updates.jenkins-ci.org/latest/timestamper.hpi
)
