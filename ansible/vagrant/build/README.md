# Building and testing Zato using Ansible

## Components

* Vagrant
* VirtualBox
* Ansible

## Vagrant boxes

Ansible creates local Vagrant machines using boxes pulled from a public
catalog of Vagrant images (mainly from Bento project:
https://github.com/chef/bento). The local boxes have to be installed
into Vagrant in a separate step.

```
$ vagrant box add ADDRESS
```

## Building Zato packages

In order to build a package, the following procedure is required:

### Variable preparation

```
 $ ansible-playbook define_vars.yml --extra-vars "[extra-vars]"
```

Extra vars being:

- `box` - box name as it appears on `vagrant box list`
- `box_name` - custom name for local box
- `box_memory` - amount of memory
- `hostname` - a host specified in the project's inventory file ('hosts')
- `ip` - IP address of the box
- `system` - one of:
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
- `release_version` - Zato version, i.e. '2.0.x'
- `package_version` - custom version of a Zato package, e.g. 'stable'
- `architecture` - one of:
    - amd64
    - i368
    - x86_64
- `rpmver` - if we want to build package for the Redhat family, e.g. 'el6.x86_64'
- `format` - package format: 'deb' or 'rpm'
- `distribution` - distribution name, e.g. 'ubuntu' or 'rhel'
- `codename` - distribution codename, e.g. 'el6', 'trusty', 'jessie'
- `branch` - a git branch the Zato package is to be build from, e.g. 'support/2.0'

The script responsible for building a Zato package, 'build.sh', needs
more parameters and it takes them from a variable file (location of which
may be specified in each playbook separately), not from command line.

### Box preparation

```
 $ ansible-playbook prepare_build_box.yml
```

### Building a package

```
 $ ansible-playbook build_package.yml --user vagrant
```

### Cleaning the build box

```
 $ ansible-playbook clean.yml
```

## Preparing test repositories

### Adding the package to a test repo

```
 $ ansible-playbook add_package_to_repo.yml \
   --extra-vars "hostname=[name-of-repo-box]" --user vagrant \
   --private-key ./vm/{{ system }}/.vagrant/machines/default/virtualbox/private_key
```

Since this playbook's purpose is to add a package to a test repo,
we need to specify repo box hostname.

## Testing Zato

### Preparing a test box

```
 $ ansible-playbook prepare_test_box.yml
```

### Testing Zato

There are many different testing playbooks and each is meant to test
one of Zato's features. For example, to test Zato quickstart
with Redis and SQLite you have to execute the following:

```
$ ansible-playbook quickstart-redis-sqlite.yml \
  --extra-vars "repo_host=[name-of-repo-box]" --user vagrant \
  --private-key ./vm/{{ system }}/.vagrant/machines/default/virtualbox/private_key

```

Extra vars:

- `repo_host` - repo box hostname

### Cleaning after testing

Example:

```
 $ ansible-playbook clean.yml
```
