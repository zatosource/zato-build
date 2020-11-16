#!/bin/bash

# Adapted from dw's zatosource/zato/.travis/setup.sh
#
# Expose a 'run' command that runs code either directly on this VM, or if IMAGE
# is set, in a Docker container on the VM instead. The mode where IMAGE is
# unset is intended for later use with OS X.
#
# When running in container mode, wire up various cache directories within the
# container back to a directory that Travis knows to keep a copy of. This
# causes package lists and PyPI source archives to be cached.
#
# In either case, "/tmp/zato-build" contains the checked out Git repository.
#
# Usage:
#   . $TRAVIS_BUILD_DIR/.travis/setup.sh
#   run cmd...
#

set -xe

sudo mkdir -p /tmp/travis-cache/packages
sudo mkdir -p /tmp/travis-cache/root/.cache/pip
sudo mkdir -p /tmp/travis-cache/var/cache/apk
sudo mkdir -p /tmp/travis-cache/var/cache/apt
sudo mkdir -p /tmp/travis-cache/var/lib/apt
sudo mkdir -p /tmp/travis-cache/var/cache/yum
sudo mkdir -p /tmp/travis-cache/apk_keys

function run()
{
    if [ "$IMAGE" ]
    then
        docker exec target "$@"
    else
        "$@"
    fi
}

function run_checking()
{
    if [ "$IMAGE" ]
    then
        docker exec target-testing "$@"
    else
        "$@"
    fi
}

if [[ -n "$IMAGE" ]]; then
  # chown everything to root so perms within container work.
  sudo chown -R root: /tmp/travis-cache

  # Arrange for the container to be downloaded and started.
  docker run \
    --name target \
    --volume $TRAVIS_BUILD_DIR:/tmp/zato-build \
    --volume /tmp/travis-cache/abuild:/root/.abuild/ \
    --volume /tmp/travis-cache/packages:/tmp/packages \
    --volume /tmp/travis-cache/root/.cache/pip:/root/.cache/pip \
    --volume /tmp/travis-cache/var/cache/apk:/var/cache/apk \
    --volume /tmp/travis-cache/var/cache/apt:/var/cache/apt \
    --volume /tmp/travis-cache/var/lib/apt:/var/lib/apt \
    --volume /tmp/travis-cache/var/cache/yum:/var/cache/yum \
    --detach \
    "$IMAGE" \
    sleep 86400

  # Arrange for the container to be downloaded and started.
  docker run \
    --name target-testing \
    -e DEBIAN_FRONTEND=noninteractive \
    -e TZ=GMT \
    -e ZATO_UPLOAD_PACKAGES=${ZATO_UPLOAD_PACKAGES} \
    -e ZATO_S3_ACCESS_KEY=${ZATO_S3_ACCESS_KEY} \
    -e ZATO_S3_SECRET_KEY=${ZATO_S3_SECRET_KEY} \
    -e ZATO_S3_BUCKET_NAME=${ZATO_S3_BUCKET_NAME} \
    --volume $TRAVIS_BUILD_DIR:/tmp/zato-build \
    --volume /tmp/travis-cache/abuild:/root/.keys/ \
    --volume /tmp/travis-cache/packages:/tmp/packages \
    --volume /tmp/travis-cache/root/.cache/pip:/root/.cache/pip \
    --volume /tmp/travis-cache/var/cache/apk:/var/cache/apk \
    --volume /tmp/travis-cache/var/cache/apt:/var/cache/apt \
    --volume /tmp/travis-cache/var/lib/apt:/var/lib/apt \
    --volume /tmp/travis-cache/var/cache/yum:/var/cache/yum \
    --detach \
    "$IMAGE" \
    sleep 86400

  # Some official images lack sudo, which breaks install.sh.
  if [[ "${IMAGE}" == *"suse"* ]]; then
    export repo="suse"
    run zypper update -y
    run zypper install -y sudo git wget curl

    # testing
    run_checking zypper update -y
    run_checking zypper install -y sudo git wget curl
  elif [ "${IMAGE:0:6}" = "centos" ]; then
    run yum -y update
    run yum -y install sudo git wget curl

    # testing
    run_checking yum -y update
    run_checking yum -y install sudo git epel-release wget curl
  elif [ "${IMAGE:0:6}" = "alpine" ]; then
    run /bin/sh -ec "apk update && apk upgrade && apk add sudo bash alpine-sdk && exec abuild-keygen -an"

    # testing
    run /bin/sh -ec "apk update && apk upgrade && apk add sudo bash git bash alpine-sdk && exec abuild-keygen -an"
  elif [ "${IMAGE:0:6}" = "ubuntu" -o "${IMAGE:0:6}" = "debian" ]; then
    run apt-get update
    run apt-get -y install sudo git lsb-release wget curl

    # testing
    run_checking apt-get update
    run_checking apt-get -y install sudo git lsb-release wget curl
  fi

  # chown everything to Travis UID so caching succeeds.
  trap "sudo chown -R $(whoami): /tmp/travis-cache" EXIT
else
  ln -sf $(pwd) /tmp/zato-build
fi
