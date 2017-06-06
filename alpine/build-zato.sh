#!/bin/sh -e

test "$#" -lt 3 && { echo "build-zato.sh: usage: ./build-zato.sh branch-name zato-version package-version" 1>&2 ; exit 100 ; }
test -z "$HOME" && { echo "build-zato.sh: HOME not set; abuild needs to run as a user with a home directory!" 1>&2 ; exit 100 ; }

BRANCH_NAME="$1"
ZATO_VERSION="$2"
PACKAGE_VERSION="$3"

# This is the file where the packager's private key (to sign the apk)
# is stored. The public key must be in the same place, with a ".rsa.pub"
# suffix.
# PACKAGER_PRIVKEY="$HOME/.abuild/dsuch@zato.io-XXXXXXXX.rsa"
PACKAGER_PRIVKEY="$HOME/.abuild/ska-devel@skarnet.org-56139463.rsa"

PREFERRED_REPOSITORY=http://dl-cdn.alpinelinux.org/alpine
ALPINE_FLAVOUR=v3.6

# These directories must be absolute.
# DO NOT use /opt/zato for ZATO_ROOT_DIR. /opt is supposed to be
# software that is NOT installed by a distribution's packaging system,
# and abuild will refuse to create a package in /opt.
# /pkg is Alpine's choice for software that installs into its own directory.

ZATO_ROOT_DIR=/pkg/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

CURDIR=`readlink -f .`

sudo mkdir -p "$ZATO_TARGET_DIR"
test "$ZATO_TARGET_DIR" != `readlink -f "$ZATO_TARGET_DIR"` && { echo "build-zato.sh: $ZATO_TARGET_DIR must be a fully resolved path!" 1>&2 ; exit 100 ; }

echo "Building zato-$ZATO_VERSION-r$PACKAGE_VERSION.apk"

TARGETS="zato-$ZATO_VERSION.tar APKBUILD bash-completion zato.post-deinstall zato.post-install zato.post-upgrade zato.pre-install zato.pre-upgrade"

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

# We need to pull py-numpy and py-numpy-f2py from community, and py-scipy
# from testing. Testing is only available from edge. It's simpler to
# rewrite our /etc/apk/repositories entirely and let abuild handle this.
  sudo sh -c "cat > /etc/apk/repositories.new && cp -f /etc/apk/repositories /etc/apk/repositories.old && mv -f /etc/apk/repositories.new /etc/apk/repositories && apk update && apk add tar alpine-sdk" <<EOF
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/main
$PREFERRED_REPOSITORY/$ALPINE_FLAVOUR/community
$PREFERRED_REPOSITORY/edge/testing
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

  rm -rf "zato-$ZATO_VERSION"
  git clone https://github.com/zatosource/zato.git "zato-$ZATO_VERSION"
  cd "zato-$ZATO_VERSION"
  for branch in `git branch -a | grep -F remotes/ | grep -vF -e HEAD -e master -e main` ; do
    git branch --track "${branch#remotes/origin/}" "$branch"
  done
  git checkout "$BRANCH_NAME"
  cd ..
  tar -cf "package-base/zato-$ZATO_VERSION.tar" "zato-$ZATO_VERSION"
  rm -rf "zato-$ZATO_VERSION"
}


make_apkbuild_dir() {
  for i in APKBUILD zato.post-deinstall zato.post-install zato.post-upgrade zato.pre-install zato.pre-upgrade ; do
    sed -e "s|@@ZATO_ROOT_DIR@@|$ZATO_ROOT_DIR|g;s|@@ZATO_TARGET_DIR@@|$ZATO_TARGET_DIR|g;s|@@ZATO_VERSION@@|$ZATO_VERSION|g;s|@@PACKAGE_VERSION@@|$PACKAGE_VERSION|g;" < "$CURDIR/package-base/$i.in" > "$CURDIR/package-base/$i"
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
  mv "$CURDIR/alpine/x86_64/zato-$ZATO_VERSION-r$PACKAGE_VERSION.apk" "$CURDIR"
  rm -rf "$CURDIR/alpine"
}

prepare_abuild
cleanup
checkout_and_make_archive
make_apkbuild_dir
call_abuild
isolate_package
cleanup
