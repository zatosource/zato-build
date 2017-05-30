#!/bin/sh -e

test "$#" -lt 3 && { echo "build-zato.sh: usage: ./build-zato.sh branch-name zato-version package-version" 1&>2 ; exit 100 ; }
test -n "$HOME" && { echo "HOME not set; abuild needs to run as a user with a home directory!" 1&>2 ; exit 100 ; }

BRANCH_NAME="$1"
ZATO_VERSION="$2"
PACKAGE_VERSION="$3"

# This is the file where the packager's private key (to sign the apk)
# is stored. The public key must be in the same place, with a ".rsa.pub"
# suffix.
PACKAGER_PRIVKEY="$HOME/.abuild/dsuch@zato.io-XXXXXXXX.rsa"

PREFERRED_REPOSITORY=http://dl-5.alpinelinux.org/alpine
ALPINE_FLAVOUR=v3.6
ZATO_ROOT_DIR=/pkg/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

CURDIR=`readlink -f .`

echo Building APK zato-$ZATO_VERSION-$PACKAGE_VERSION


prepare_abuild() {

# Ensure abuild can access the packager's key
  mkdir -p "$HOME/.abuild"
  echo "PACKAGER_PRIVKEY=$PACKAGER_PRIVKEY" > "$HOME/.abuild/abuild.conf"

# We need to pull py-numpy and py-numpy-f2py from community, and py-scipy
# from testing. Testing is only available from edge. It's simpler to
# rewrite our /etc/apk/repositories entirely and let abuild handle this.
sudo sh -c "cat >> /etc/apk/repositories && apk update && apk add tar alpine-sdk" <<EOF
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/main
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/community
$PREFERRED_REPOSITORY/edge/testing
EOF
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


prepare_abuild
cleanup
checkout_and_make_archive
make_apkbuild_dir
call_abuild
