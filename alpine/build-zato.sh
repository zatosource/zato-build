#!/bin/sh -e

# This script will build the desired apk file in the directory it resides.
# The produced apk file should then be added to the remote Alpine
# repository and the index should be recomputed and re-signed; the
# instructions to do so are available at
# https://gitlab.com/zatosource/alpine-linux/wikis/how-to-manage-an-alpine-linux-repository


test "$#" -ge 2 || { echo "build-zato.sh: usage: ./build-zato.sh branch-name zato-version [ package-version ]" 1>&2 ; exit 100 ; }
test -n "$HOME" || { echo "build-zato.sh: HOME not set; abuild needs to run as a user with a home directory!" 1>&2 ; exit 100 ; }

BRANCH_NAME="$1"
ZATO_VERSION="$2"

# The acceptable values for package-version are:
# * nothing or "stable", for stable versions. (The Alpine version will then have no suffix.)
# * "alpha", "beta", "pre" or "rc" followed by one or more digits.
# This is a versioning convention coming from Gentoo, that Alpine also follows.

PACKAGE_VERSION="$3"
PY_BINARY=${4:-python}

apk add $PY_BINARY

# Python 2 dependencies
PYTHON_DEPENDENCIES="python2-dev"
PYTHON_VERSION=""
if [[ $(${PY_BINARY} -c 'import sys; print(sys.version_info[:][0])') -eq 3 ]]
then
    # Python 3 dependencies
    PYTHON_DEPENDENCIES="python3-dev"
    PYTHON_VERSION="-python3"
fi

COMPLETE_VERSION="${ZATO_VERSION}"
# if test -z "${PACKAGE_VERSION}" || test "${PACKAGE_VERSION}" = "stable" ; then
#     COMPLETE_VERSION="${ZATO_VERSION}"
# else
#   COMPLETE_VERSION="${ZATO_VERSION}_${PACKAGE_VERSION}"
fi

apk version --check --quiet "${COMPLETE_VERSION}" || { echo "build-zato.sh: version $COMPLETE_VERSION is not valid for apk: suffixes must be {alpha|beta|pre|rc}[0-9]+" 1>&2 ; exit 100 ; }


# This is the file where the packager's private key (to sign the apk)
# is stored. The public key must be in the same place, with a ".rsa.pub"
# suffix.

# PACKAGER_PRIVKEY="$HOME/.abuild/dsuch@zato.io-XXXXXXXX.rsa"
PACKAGER_PRIVKEY=${PACKAGER_PRIVKEY:-$HOME/.abuild/ska-devel@skarnet.org-56139463.rsa}


# Where we get Alpine from, and what version

PREFERRED_REPOSITORY=${PREFERRED_REPOSITORY:-http://dl-cdn.alpinelinux.org/alpine}
ALPINE_FLAVOUR=${ALPINE_FLAVOUR:-v3.8}


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
  cd ..
  tar -cf "package-base/zato-$COMPLETE_VERSION.tar" "zato-$COMPLETE_VERSION"
  rm -rf "zato-$COMPLETE_VERSION"
}


make_apkbuild_dir() {
  for i in $ABUILD_FILES ; do
    sed -e "s|@@ZATO_ROOT_DIR@@|$ZATO_ROOT_DIR|g;s|@@ZATO_TARGET_DIR@@|$ZATO_TARGET_DIR|g;s|@@ZATO_VERSION@@|$ZATO_VERSION|g;s|@@PACKAGE_VERSION@@|$PACKAGE_VERSION|g;s|@@COMPLETE_VERSION@@|$COMPLETE_VERSION|g;s|@@PYTHON_DEPENDENCIES@@|$PYTHON_DEPENDENCIES|g;s|@@PYTHON_VERSION@@|$PYTHON_VERSION|g;" < "$CURDIR/package-base/$i.in" > "$CURDIR/package-base/$i"
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
