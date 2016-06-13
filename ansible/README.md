# Building and testing Zato packages using Ansible <a id="building-testing"></a>

## Components <a id="components"></a>

* Vagrant
* VirtualBox
* Ansible 2.0.1.0

## Vagrant boxes

Optionally, Ansible creates local Vagrant machines using boxes pulled from a public
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

- `base_box` - name of Vagrant base box as it appears on `vagrant box list`
- `box_name` - custom name for local box
- `box_memory` - amount of memory
- `box_hostname` - a host specified in the project's inventory file ('hosts')
- `box_ip` - IP address of the box
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
- `package_version` - Zato package version, i.e. '2.0.x'
- `package_release` - name of release, e.g. 'stable'
- `architecture` - one of:
    - amd64
    - i368
    - x86_64
- `format` - package format: 'deb' or 'rpm'
- `distribution` - distribution name, e.g. 'ubuntu' or 'rhel'
- `codename` - distribution codename, e.g. 'el6', 'trusty', 'jessie'
- `branch` - a git branch the Zato package is to be build from, e.g. 'support/2.0'
- `repo_host` - host where repo holding Zato packages is located
- `root_dir` - project's root directory; you can use `` `echo $PWD` `` as default value

The script responsible for building a Zato package, 'build.sh', needs
more arguments and it takes them from a variable file (location of which
may be specified in each playbook separately), not from command line.

### Box preparation

```
 $ ansible-playbook prepare_box.yml --extra-vars "user=[USER]"
```

### Building a package

```
 $ ansible-playbook build_package.yml
```

### Cleaning the build box

```
 $ ansible-playbook clean.yml
```

## Preparing test repositories

### Adding the package to a test repo

```
 $ ansible-playbook add_package_to_repo.yml
```

## Testing Zato

### Preparing a test box

```
 $ ansible-playbook prepare_box.yml --extra-vars "user=[USER]"
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
