#!/bin/bash

set -xe
. $TRAVIS_BUILD_DIR/.travis/setup.sh

name="${IMAGE:0:6}"
version="${IMAGE##${name}:}"
ZATO_VERSION=${ZATO_VERSION:-3.0.0}

case "$name" in
  centos) repo="rhel$version" ;;
  debian|ubuntu) repo="deb" ;;
  alpine) repo="alpine" ; export ALPINE_FLAVOUR="v$version" ;;
esac

run bash -ec "cd /tmp/zato-build/$repo && exec ./build-zato.sh main \"$ZATO_VERSION\" \"${PY_BINARY:-python}\" \"${PACKAGE_VERSION}\" travis"

echo "Artifacts:"
find /tmp/travis-cache/packages -type f
run_checking bash -ec "cd /tmp/zato-build/.travis && exec ./test_install.sh \"$ZATO_VERSION\" \"${PY_BINARY:-python}\" \"${PACKAGE_VERSION}\""
