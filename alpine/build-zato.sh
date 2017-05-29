#!/bin/sh -e

test "$#" -lt 3 && { echo "build-zato.sh: usage: ./build-zato.sh branch-name zato-version package-version" 1&>2 ; exit 100 ; }

BRANCH_NAME="$1"
ZATO_VERSION="$2"
PACKAGE_VERSION="$3"

CURDIR=`readlink -f .`

ZATO_ROOT_DIR=/pkg/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

echo Building APK zato-$ZATO_VERSION-$PACKAGE_VERSION


prepare_build() {
  sudo apk update
  sudo apk add tar alpine-sdk py-numpy

# We want to let abuild manage as many dependencies as possible itself,
# but it cannot handle dependencies from stable to edge. So we just
# pre-install the edge packages by hand.

  sudo apk add py-numpy-f2py --update-cache --repository http://dl-5.alpinelinux.org/alpine/edge/community
  sudo apk add py-scipy --update-cache --repository http://dl-5.alpinelinux.org/alpine/edge/testing

  # TODO: Edit a suitable /etc/abuild.conf and/or $HOME/.abuild/abuild.conf
  # We need developer contact and keypair.
}


cleanup() {
  rm -rf $CURDIR/package-base/srcdir $CURDIR/package-base/zato-archive.tar $CURDIR/package-base/APKBUILD $CURDIR/zato-$ZATO_VERSION
}


checkout_and_make_archive() {

# abuild cannot fetch directly from a git repository.
# We fetch here, and prepare the clone, then archive it into a
# local file. The APKBUILD uses that file as its main source.

  rm -rf zato-$ZATO_VERSION
  git clone https://github.com/zatosource/zato.git zato-$ZATO_VERSION
  cd zato-$ZATO_VERSION
  for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master ` ; do
    git branch --track ${branch#remotes/origin/} $branch
  done
  git checkout $BRANCH_NAME
  cd ..
  tar --exclude-vcs -cf package-base/zato-archive.tar zato-$ZATO_VERSION
  rm -rf zato-$ZATO_VERSION
}


make_apkbuild_dir() {
  sed -e "s|@@ZATO_ROOT_DIR@@|$ZATO_ROOT_DIR|g;s|@@ZATO_TARGET_DIR@@|$ZATO_TARGET_DIR|g;s|@@ZATO_VERSION@@|$ZATO_VERSION|g;s|@@PACKAGE_VERSION@@|$PACKAGE_VERSION|g;" < $CURDIR/package-base/APKBUILD.in > $CURDIR/package-base/APKBUILD
  cp $CURDIR/../bash_completion/zato $CURDIR/package-base/bash-completion
  cd package-base
  abuild checksum
  cd ..
}


call_abuild() {
  cd package-base
  abuild -r
  cd ..
}


prepare_build
cleanup
checkout_and_make_archive
make_apkbuild_dir
call_abuild
