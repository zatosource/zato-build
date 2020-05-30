#!/bin/bash

set -xe
if [[ -z "`docker ps -a|grep target`" ]]; then
    . $TRAVIS_BUILD_DIR/.travis/setup.sh
fi

name="${IMAGE:0:6}"
version="${IMAGE##${name}:}"
ZATO_VERSION=${ZATO_VERSION:-3.0.0}
basepath="$(dirname "$(readlink -e $0)")"

case "$name" in
  centos) repo="rhel$version" ;;
  debian|ubuntu) repo="deb" ;;
  alpine) repo="alpine" ; export ALPINE_FLAVOUR="v$version" ;;
esac

if [[ "$repo" == "alpine" ]]; then
    run bash -ec "if ! test -d /home/zato;then adduser -s /bin/bash -h /home/zato -u 1000 -G abuild -D zato;fi;echo 'ALL ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/zato"
    run bash -ec "set -x;cd /tmp/zato-build/$repo && chown zato -R /tmp/zato-build/$repo && exec sudo -Hns -u zato ./build-zato.sh ${ZATO_BRANCH:-main} \"$ZATO_VERSION\" \"${PY_BINARY:-python}\" '${PACKAGE_VERSION:-stable}' travis"
else
    run bash -ec "cd /tmp/zato-build/$repo && exec ./build-zato.sh ${ZATO_BRANCH:-main} \"$ZATO_VERSION\" \"${PY_BINARY:-python}\" \"${PACKAGE_VERSION}\" travis"
fi

echo "Artifacts:"
find /tmp/travis-cache/packages -type f
run_checking bash -ec "cd /tmp/zato-build/.travis && exec ./test_install.sh \"$ZATO_VERSION\" \"${PY_BINARY:-python}\" \"${PACKAGE_VERSION}\""

if [[ -n "${CREATE_DOCKER_IMAGES}" && -n "${GITLAB_USER}" && -n "${GITLAB_TOKEN}" ]]; then
    $TRAVIS_BUILD_DIR/.travis/upload_docker.sh "${GITLAB_USER}" "${GITLAB_TOKEN}" $(find /tmp/travis-cache/packages -type f -name \*.deb | head -n 1) "${CREATE_DOCKER_IMAGES}"
fi
