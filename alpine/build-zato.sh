#!/bin/sh -e

# This script will build the desired apk file in the directory it resides.
# The produced apk file should then be added to the remote Alpine
# repository and the index should be recomputed and re-signed; the
# instructions to do so are available at
# https://gitlab.com/zatosource/alpine-linux/wikis/how-to-manage-an-alpine-linux-repository


test "$#" -ge 2 || { echo "build-zato.sh: usage: ./build-zato.sh branch-name zato-version [ package-version ]" 1>&2 ; exit 100 ; }
test -n "$HOME" || { echo "build-zato.sh: HOME not set; abuild needs to run as a user with a home directory!" 1>&2 ; exit 100 ; }

usage() {
  echo "$0 BRANCH_NAME ZATO_VERSION PYTHON_EXECUTABLE [PACKAGE_VERSION] [PROCESS]"
  echo ""
  echo "BRANCH_NAME: zatosource/zato branch name to build (e.g. master)"
  echo "ZATO_VERSION: zato version to build (e.g. 3.0.0)"
  echo "PYTHON_EXECUTABLE: Python executable to use (e.g. python, python2 or python3)"
  echo "PACKAGE_VERSION: (optional) package version to build. The acceptable values for package-version are:"
  echo "                 * \"\" (empty) or \"stable\", for stable versions."
  echo "                 * \"alpha\", \"beta\", \"pre\" or \"rc\" followed by one or more digits."
  echo "PROCESS: (optional) should be \"travis\" if run inside TravisCI"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

if [ -z "$1" ]; then
  echo Argument 1 must be the branch name from zatosource/zato used to build the package.
  exit 1
fi

if [ -z "$2" ] || [ -z "$(echo $2 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+')" ]; then
  echo Argument 2 must be the Zato version to build.
  exit 1
fi

if [ -z "$3" ] || [ -z "$(echo $3 | grep -E '^python[2,3]?\.?')" ]; then
  echo Argument 3 must be the Python executable to use e.g. python, python2 or python3.
  exit 1
fi

if [ -n "$4" ] && [ -z "$(echo $4 | grep -E '^(stable|alpha|beta|pre|rc)')" ]; then
  echo Argument 4 is the release level of the build. The value has to be empty or be one of: stable, alpha, beta, pre or rc.
  exit 1
fi

BRANCH_NAME="$1"
ZATO_VERSION="$2"
PY_BINARY="${3:-python3}"

# The acceptable values for package-version are:
# * nothing or "stable", for stable versions. (The Alpine version will then have no suffix.)
# * "alpha", "beta", "pre" or "rc" followed by one or more digits.
# This is a versioning convention coming from Gentoo, that Alpine also follows.
PACKAGE_VERSION="${4}"
TRAVIS_PROCESS_NAME="$5"

ALPINE_VERSION=$(cat /etc/alpine-release)

if [ "${PY_BINARY}" != "python3" ]; then
  echo "Unsupported Python version"
  exit 1
fi

if test -z "${PACKAGE_VERSION}" || test "${PACKAGE_VERSION}" = "stable" ; then
  COMPLETE_VERSION="${ZATO_VERSION}"
else
  COMPLETE_VERSION="${ZATO_VERSION}_${PACKAGE_VERSION}"
fi

apk version --check --quiet "${COMPLETE_VERSION}" || { echo "build-zato.sh: version $COMPLETE_VERSION is not valid for apk: suffixes must be {alpha|beta|pre|rc}[0-9]+" 1>&2 ; exit 100 ; }

# This is the file where the packager's private key (to sign the apk)
# is stored. The public key must be in the same place, with a ".rsa.pub"
# suffix.

# PACKAGER_PRIVKEY="$HOME/.abuild/dsuch@zato.io-XXXXXXXX.rsa"

PACKAGER="$(grep '# Maintainer:' package-base/APKBUILD.in|sed -e 's|.*Maintainer: ||')"
abuild-keygen -an

if test -n "$(find $HOME/.abuild -type f -name \*.rsa)"; then
    PACKAGER_PRIVKEY="$(find $HOME/.abuild -type f -name \*.rsa|head -n 1)"
else
    echo "no sign key found"
    exit 1
fi
# Where we get Alpine from, and what version

PREFERRED_REPOSITORY=${PREFERRED_REPOSITORY:-http://dl-cdn.alpinelinux.org/alpine}
ALPINE_FLAVOUR=${ALPINE_FLAVOUR}
if test -z "${ALPINE_FLAVOUR}"; then
    ALPINE_FLAVOUR="v${ALPINE_VERSION%.*}"
fi


# These directories must be absolute.
# DO NOT use /opt/zato for ZATO_ROOT_DIR. /opt is supposed to be
# software that is NOT installed by a distribution's packaging system,
# and abuild will refuse to create a package in /opt.
# /pkg is Alpine's choice for software that installs into its own directory.
# For compatibility, an /opt/zato -> /pkg/zato symlink will be created
# by the pre-install script.

ZATO_ROOT_DIR=/pkg/zato
ZATO_TARGET_DIR="$ZATO_ROOT_DIR/$COMPLETE_VERSION"

CURDIR=`readlink -f .`
sudo mkdir -p "$ZATO_TARGET_DIR"
test "$ZATO_TARGET_DIR" = `readlink -f "$ZATO_TARGET_DIR"` || { echo "build-zato.sh: $ZATO_TARGET_DIR must be a fully resolved path!" 1>&2 ; exit 100 ; }

echo "Building zato-$COMPLETE_VERSION-r0.apk"

ABUILD_FILES="APKBUILD zato.post-deinstall zato.post-install zato.post-upgrade zato.pre-deinstall zato.pre-install zato.pre-upgrade zato.bashrc"
TARGETS="zato-$COMPLETE_VERSION.tar bash-completion $ABUILD_FILES"

prepare_abuild() {

# Ensure abuild can access the packager's keypair

  mkdir -p "$HOME/.abuild"
  echo "PACKAGER_PRIVKEY=$PACKAGER_PRIVKEY" > "$HOME/.abuild/abuild.conf"
  pubkey=`basename $PACKAGER_PRIVKEY`.pub
  if test -f "/etc/apk/keys/$pubkey" ; then
    :
  else
    sudo cp -f ${PACKAGER_PRIVKEY}.pub /etc/apk/keys
  fi


# We build a maximum of dependencies via wheels, but there are still
# a few system packages we depend on.

  sudo sh -c "cat > /etc/apk/repositories.new && cp -f /etc/apk/repositories /etc/apk/repositories.old && mv -f /etc/apk/repositories.new /etc/apk/repositories && apk update && apk add tar alpine-sdk" <<EOF
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/main
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/community
EOF
}


cleanup() {
  for i in $TARGETS ; do
    rm -f "$CURDIR/package-base/$i"
  done
}


checkout_and_make_archive() {

# abuild cannot fetch directly from a git repository.
# We fetch here, and prepare the clone, then archive it into a
# local file. The APKBUILD uses that file as its main source.

  rm -rf "zato-$COMPLETE_VERSION"
  git clone --depth 1 --no-single-branch https://github.com/zatosource/zato.git "zato-$COMPLETE_VERSION"
  cd "zato-$COMPLETE_VERSION"
  for branch in `git branch -a | grep -F remotes/ | grep -vF -e HEAD -e master -e main` ; do
    git branch --track "${branch#remotes/origin/}" "$branch"
  done
  git checkout "$BRANCH_NAME"
  sed -i -e 's/scipy==.*/scipy/' code/requirements.txt
  cd ..
  tar -cf "package-base/zato-$COMPLETE_VERSION.tar" "zato-$COMPLETE_VERSION"
  rm -rf "zato-$COMPLETE_VERSION"
}


make_apkbuild_dir() {
  for i in $ABUILD_FILES ; do
    sed -e "s|@@ZATO_ROOT_DIR@@|$ZATO_ROOT_DIR|g;s|@@ZATO_TARGET_DIR@@|$ZATO_TARGET_DIR|g;s|@@ZATO_VERSION@@|$ZATO_VERSION|g;s|@@PACKAGE_VERSION@@|$PACKAGE_VERSION|g;s|@@COMPLETE_VERSION@@|$COMPLETE_VERSION|g;s|@@PY_BINARY@@|$PY_BINARY|g;" < "$CURDIR/package-base/$i.in" > "$CURDIR/package-base/$i"
  done
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


isolate_package() {
  if [ -n "$TRAVIS_PROCESS_NAME" ] && [ $TRAVIS_PROCESS_NAME = "travis" ]; then
    [ -d "/tmp/packages/alpine/${ALPINE_VERSION%.*}" ] || mkdir -p /tmp/packages/alpine/${ALPINE_VERSION%.*}/
    cp "$CURDIR/alpine/x86_64/zato-$COMPLETE_VERSION-r0.apk" /tmp/packages/alpine/${ALPINE_VERSION%.*}/
  fi
  mv "$CURDIR/alpine/x86_64/zato-$COMPLETE_VERSION-r0.apk" "$CURDIR"
  rm -rf "$CURDIR/alpine"
}


prepare_abuild
cleanup
checkout_and_make_archive
make_apkbuild_dir
call_abuild
isolate_package
cleanup
