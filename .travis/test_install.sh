#!/bin/bash

if [ -z "$1" ]; then
  echo Argument 1 must be Zato version
  exit 2
fi

basepath="$(dirname "$(readlink -e $0)")"

ZATO_VERSION=$1
PY_BINARY=${2:-python}
# PACKAGE_VERSION=$3

cd /tmp/packages || exit 1

if [ "$(type -p apt-get)" ]; then
  apt-get update -y

  if ! [ -x "$(command -v lsb_release)" ]; then
    sudo apt-get install -y lsb-release
  fi

  if ! [ -e "/usr/share/zoneinfo/GMT" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
  fi

  if ! [ -e "/etc/localtime" ]; then
    ln -s /usr/share/zoneinfo/GMT /etc/localtime
  fi

  sudo dpkg-reconfigure --frontend noninteractive tzdata

  if [[ $(dpkg -s apt | grep -i version|cut -d ' ' -f 2|cut -d '.' -f 1,2) > 1.0 ]];then
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
      find /tmp/packages/ -type f -name \*.deb -exec apt-get install -y {} \;
  else
      find /tmp/packages/ -type f -name \*.deb -exec dpkg -i  {} \;

      # fix dependencies
      DEBIAN_FRONTEND=noninteractive dpkg --configure -a
      DEBIAN_FRONTEND=noninteractive apt-get install -f -y || exit 1
  fi

elif [ "$(type -p yum)" ]; then
  INSTALL_CMD="yum"

  if [ "$(type -p dnf)" ]
  then
      INSTALL_CMD="dnf"
  fi

  RHEL_VERSION=el7
  if ! [ -x "$(command -v lsb_release)" ]; then
      sudo ${INSTALL_CMD} install -y redhat-lsb-core
  fi

  if [[ "$(lsb_release -sir)" =~ '^CentOS.8\.' ]]
  then
    sudo ${INSTALL_CMD} install -y 'dnf-command(config-manager)'
    sudo ${INSTALL_CMD} config-manager --set-enabled PowerTools
  elif [[ ${PY_BINARY} == "python3" && -z "$(lsb_release -r|grep '\s8.')" ]]; then
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

  find /tmp/packages/ -type f -name \*.rpm -exec ${INSTALL_CMD} install -y {} \;
elif [ "$(type -p apk)" ]; then
  apk update
  apk add python py-pip py-setuptools git ca-certificates
  pip install python-dateutil
  abuild-keygen -ani || exit 1
  ALPINE_VERSION="$(cat /etc/alpine-release)"

  echo "@custom /tmp/packages/alpine/${ALPINE_VERSION%.*}/" >> /etc/apk/repositories
  pushd /tmp/packages/alpine/${ALPINE_VERSION%.*}/ || exit 1
      apk index -o APKINDEX.tar.gz *.apk
      abuild-sign APKINDEX.tar.gz
  popd || exit 1
  apk add zato@custom
else
  echo "install.sh: Unsupported OS: could not detect apt-get, yum, or apk." >&2
  exit 1
fi
if [[ ${PY_BINARY} == "python3" ]]; then
  PY_VERSION="py3."
else
  PY_VERSION="py2."
fi

head -n 1 /opt/zato/current/bin/zato

curl https://dl.min.io/client/mc/release/linux-amd64/mc > /tmp/minio-client && chmod +x /tmp/minio-client
/tmp/minio-client config host add s3 https://s3.amazonaws.com "${ZATO_S3_ACCESS_KEY}" "${ZATO_S3_SECRET_KEY}" --api S3v4

su - zato -c "$(head -n 1 /opt/zato/current/bin/zato|cut -d '!' -f 2) -c 'import sys; print(sys.version_info)' 2>&1"
su - zato -c 'zato --version 1>/tmp/zato-version 2>&1'

cat /tmp/zato-version

if [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]]; then
  [[ -n "$(grep 'Zato ' /tmp/zato-version)" ]] && echo "Zato execution: ok"
  [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]] && echo "Python version: ok"
  echo "Zato version output: $(cat /tmp/zato-version)"
  if [[ -n "${ZATO_UPLOAD_PACKAGES}" && "${ZATO_UPLOAD_PACKAGES}" == "y" ]]; then
      echo "Tests passed..Uploading packages"
      /tmp/minio-client cp -r /tmp/packages/ s3/zato.travis.1/
      if [[ $? -eq 0 ]]; then
          echo "Package uploaded"
      else
          echo "Package upload failed"
          exit 1
      fi
  fi
else
  echo "Zato failed to pass tests"
  echo -n "Zato execution:"
  if [[ -n "$(grep 'Zato ' /tmp/zato-version)" ]]; then
    echo "ok"
  else
    echo "error"
  fi
  echo -n "Python version ($PY_VERSION):"
  if [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]]; then
    echo "ok"
  else
    echo "error"
  fi
  echo "Zato version output: $(cat /tmp/zato-version)"
  exit 1
fi
