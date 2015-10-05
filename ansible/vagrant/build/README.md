# Testing Zato using Ansible

## Components

* Vagrant
* VirtualBox
* Ansible

## Vagrant boxes

Ansible builds local Vagrant boxes using boxes pulled from a public
catalog of Vagrant images (mainly from Bento project:
https://github.com/chef/bento). The local boxes have to be installed
into Vagrant in a separate step.

```
$ vagrant box add ADDRESS
```

## Building Zato packages

In order to build a package, the following procedure is required:

### Box preparation

```
 $ ansible-playbook prepare_build_box.yml --extra-vars "[extra-vars]"
```

Extra vars being:

- box - box name as it appears on `vagrant box list`
- box_name - custom box name
- box_memory - amount of memory the box will have
- hostname - box's hostname
- ip - IP address of the box
- system - one of:
    - debian-7-32
    - debian-7-64
    - debian-8-64
    - redhat-6-32
    - redhat-6-64
    - redhat-7-64
    - ubuntu-12.04-32
    - ubuntu-12.04-64
    - ubuntu-14.04-32
    - ubuntu-14.04-64
- release_version - Zato version, e.g. '2.0.5'
- package_version - custom version of a package, e.g. 'stable'
- rpmver - if we want to build package for the Redhat family
- branch - git branch the Zato package is to be build from, e.g. 'support/2.0'

### Building a package

```
 $ ansible-playbook build_package.yml --extra-vars "[extra-vars]" --user-vagrant --ask-pass
```

There's only one extra var to this playbook:

- release_version
- package_version
- system
- branch
- codename
- rpmver
- host - a host specified in the project's inventory file (usually called 'hosts')

The script responsible for building a Zato package needs more parameters and it
takes them from a variable file (location of which may be specified in each playbook
separately), not from command line.

### Copying the new package to a repo box directory

```
 $ ansible-playbook copy_package_after_build.yml --extra-vars "[extra-vars]"
```

Extra vars for this playbook are:

- system
- release_version
- package_version
- rpmver
- architecture - one of:
    - amd64
    - i368
    - x86_64
- distribution - distribution name, e.g. 'ubuntu' or 'debian'
- format - package format: 'deb' or 'rpm'
- destination - path to either deb repo box or rpm repo box directory

### Adding the package to a test repo

```
 $ ansible-playbook add_package_to_repo.yml --extra-vars "[extra-vars]" --user vagrant --ask-pass
```

Extra vars:

- system
- release_version
- package_version
- rpmver
- architecture
- codename - distribution codename, e.g. 'el6', 'trusty', 'jessie'
- distribution
- format
- host

### Cleaning the build box

Example:

```
 $ ansible-playbook clean.yml --extra-vars "system=ubuntu-14.04-64"
```

### Preparing a test box

```
 $ ansible-playbook clean.yml --extra-vars "[extra-vars]"
```

Extra vars:

- box
- box_name
- box_memory
- hostname
- ip
- system
- release_version
- package_version
- rpmver
- branch

### Testing Zato

There are many different playbooks and each is meant to test
one of Zato's features. For example, to test Zato quickstart
with Redis and SQLite you have to execute the following:

```
$ ansible-playbook quickstart-redis-sqlite.yml --extra-vars "" --user vagrant --ask-pass
```

Extra vars:

- release_version
- package_version
- rpmver
- system
- branch
- codename
- project_root - project's root directory, specified in vars/vars.yml file

### Cleaning after testing

Example:

```
 $ ansible-playbook clean.yml --extra-vars "system=ubuntu-14.04-64"
```
