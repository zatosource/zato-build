Setup building and testing infrastructure
=========================================

Prerequisites
-------------

In order for the setup to be successfull, you need to install the following
software:

* [Ansible](https://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-apt-ubuntu)
* openjdk-7-jre
* [Vagrant](https://docs.vagrantup.com/v2/installation/index.html)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

Setup script
------------

The script clones 'zato-build' repository where all Ansible playbooks
are [located](https://github.com/zatosource/zato-build/ansible/vagrant/build).
Then it downloads [Jenkins](https://jenkins-ci.org/). In next step
it downloads and installs all required [Vagrant boxes](https://docs.vagrantup.com/v2/boxes.html)
from [bento project](https://github.com/chef/bento). Finally, it runs
an Ansible playbook to test if the application works as expected, and then
it checks Jenkins by running a test job.
