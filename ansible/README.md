# Building and testing Zato packages using Ansible <a id="building-testing"></a>

## Components <a id="components"></a>

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

- `system` - one of:
    - debian-7-32
    - debian-7-64
    - debian-8-32
    - debian-8-64
    - redhat-6-32
    - redhat-6-64
    - redhat-7-64
    - ubuntu-12.04-32
    - ubuntu-12.04-64
    - ubuntu-14.04-32
    - ubuntu-14.04-64
    - ubuntu-16.04-32
    - ubuntu-16.04-64
- `package_version` - Zato package version, i.e. '2.0.x'
- `package_release` - name of release, e.g. 'stable'
- `architecture` - one of:
    - amd64
    - i368
    - x86_64
- `branch` - a git branch the Zato package is to be build from, e.g. 'support/2.0'

### Box preparation

```
 $ ansible-playbook 
```

### Building a package

```
 $ ansible-playbook 
```

### Cleaning the build box

```
 $ ansible-playbook 
```

## Preparing test repositories

### Adding the package to a test repo

```
 $ ansible-playbook 
```

## Testing Zato

### Preparing a test box

```
 $ ansible-playbook 
```

### Testing Zato

There are many different testing playbooks and each is meant to test
one of Zato's features. For example, to test Zato quickstart
environment with Redis and SQLite you have to execute the following:

```
$ ansible-playbook quickstart_redis_sqlite.yml

```

### Cleaning after testing

Example:

```
 $ ansible-playbook clean.yml
```
