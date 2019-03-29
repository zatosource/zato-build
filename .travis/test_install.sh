#!/bin/bash

if [ -z "$1" ]; then
  echo Argument 1 must be Zato version
  exit 2
fi

ZATO_VERSION=$1
# PACKAGE_VERSION=$3
PY_BINARY=${2:-python}

cd /tmp/zato-build/packages/ || exit 1

if [ "$(type -p apt-get)" ]; then
  apt-get install -y gnupg dpkg-dev dpkg-sig apt-utils
  mkdir -p pool/main
  for i in zato-$ZATO_VERSION-*_$ARCH.deb;do
    mv $i pool/main
  done
  DIST_NAME="$(grep 'deb ' /etc/apt/sources.list|grep -v '#'|head -n 1|awk '{print $3}')"

  cat > release.conf <<BLOCK
APT::FTPArchive::Release::Codename "${DIST_NAME}";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Label "Zato APT Testing Repository";
APT::FTPArchive::Release::Architectures "amd64";
BLOCK

  [[ -d dists/${DIST_NAME}/main/binary-amd64/ ]] || mkdir -p dists/${DIST_NAME}/main/binary-amd64/
  apt-ftparchive --arch amd64 packages pool/main > dists/${DIST_NAME}/main/binary-amd64/Packages
  gzip -fk dists/${DIST_NAME}/main/binary-amd64/Packages
  apt-ftparchive contents pool/main > dists/${DIST_NAME}/main/Contents-amd64
  gzip -fk dists/${DIST_NAME}/main/Contents-amd64
  apt-ftparchive release dists/${DIST_NAME}/main/binary-amd64 > dists/${DIST_NAME}/main/binary-amd64/Release
  apt-ftparchive release -c release.conf dists/${DIST_NAME} > dists/${DIST_NAME}/Release

  # install package
  cat > /etc/apt/sources.list.d/zato.list << EOF
deb [ arch=amd64 ] file:///tmp/zato-build/packages/ $DIST_NAME main
EOF
  apt-get update --allow-insecure-repositories
  apt-get install --allow-insecure-repositories -y zato || exit 1
elif [ "$(type -p yum)" ]; then
  yum install -y createrepo gnutls-devel
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
  createrepo .
  # install package
  sudo cat > /etc/yum.repos.d/nubity.repo << EOF
[zato]
name=Zato RPM Testing Repository
enabled=1
autorefresh=1
baseurl=file:///tmp/zato-build/packages/
gpgcheck=0
EOF
  yum install -y zato
# elif [ "$(type -p apk)" ]
# then
else
  echo "install.sh: Unsupported OS: could not detect apt-get, yum, or apk." >&2
  exit 1
fi
