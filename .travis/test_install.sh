#!/bin/bash

if [ -z "$1" ]; then
  echo Argument 1 must be Zato version
  exit 2
fi

ZATO_VERSION=$1
PY_BINARY=${2:-python}
# PACKAGE_VERSION=$3

cd /tmp/packages || exit 1

if [ "$(type -p apt-get)" ]; then
  apt-get update

  if ! [ -x "$(command -v lsb_release)" ]; then
    sudo apt-get install -y lsb-release
  fi

  if ! [ -x "$(command -v timedatectl)" ]; then
    timedatectl show
    # sudo timedatectl set-timezone GMT
  else
    ls -l /etc/localtime
  fi

  for i in $(find "/tmp/packages/" -type f -name \*.deb); do
    dpkg -i $i
  done
  apt-get install -f -y || exit 1
elif [ "$(type -p yum)" ]; then
  RHEL_VERSION=el7
  if [[ ${PY_BINARY} == "python3" ]]; then
    sudo yum install -y centos-release-scl-rh
    sudo yum-config-manager --enable centos-sclo-rh-testing

    # On RHEL, enable RHSCL and RHSCL-beta repositories for you system:
    sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
    sudo yum-config-manager --enable rhel-server-rhscl-beta-7-rpms

    # 2. Install the collection:
    sudo yum install -y rh-python36

    # 3. Start using software collections:
    # scl enable rh-python36 bash
    source /opt/rh/rh-python36/enable
  fi

  for i in $(find /tmp/packages/ -type f -name \*.rpm); do
    yum install -y $i
  done
  # elif [ "$(type -p apk)" ]
  # then
else
  echo "install.sh: Unsupported OS: could not detect apt-get, yum, or apk." >&2
  exit 1
fi

su - zato -c 'head -n 2 /opt/zato/current/bin/zato;zato --version' || exit 1
