#!/bin/bash

if [[ -z "$1" ]]
then
    echo Argument 1 must be branch name
    exit 1
fi

if [[ -z "$2" ]]
then
    echo Argument 2 must be Zato version
    exit 2
fi

if [[ -z "$3" ]]
then
    echo Argument 3 must be package version
    exit 3
fi

BRANCH_NAME=$1
ZATO_VERSION=$2
PACKAGE_VERSION=$3

CURDIR="${BASH_SOURCE[0]}";RL="readlink";([[ `uname -s`=='Darwin' ]] || RL="$RL -f")
while([ -h "${CURDIR}" ]) do CURDIR=`$RL "${CURDIR}"`; done
N="/dev/null";pushd .>$N;cd `dirname ${CURDIR}`>$N;CURDIR=`pwd`;popd>$N

SOURCE_DIR=$CURDIR/package-base
ARCH=`dpkg --print-architecture`
RELEASE_NAME=`lsb_release -cs`

ZATO_ROOT_DIR=/opt/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

# Default libumfpack version on Debian 7 and Ubuntu 12.04
LIBUMFPACK_VERSION=5.4.0

# Ubuntu 14.04 needs a different one
if command -v lsb_release > /dev/null; then
    release=$(lsb_release -r | cut -f2)
    if [[ "$release" == "14.04" ]]; then
        LIBUMFPACK_VERSION=5.6.2
    fi
fi

echo Building `lsb_release -is` DEB zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH-$RELEASE_NAME

function cleanup {
    sudo rm -rf $ZATO_TARGET_DIR
    sudo rm -rf $CURDIR/BUILDROOT
}

function checkout {
    sudo mkdir -p $ZATO_TARGET_DIR
    sudo chown $USER $ZATO_TARGET_DIR

    git clone https://github.com/zatosource/zato.git $ZATO_TARGET_DIR
    cd $ZATO_TARGET_DIR

    for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
        git branch --track ${branch#remotes/origin/} $branch
    done

    git checkout $BRANCH_NAME
}

function install_zato {

    cd $ZATO_TARGET_DIR/code
    cp ../LICENSE.txt .
    cp ../licenses_3rd_party.txt .

    cd $ZATO_TARGET_DIR
    shopt -s dotglob
    mv code/* .
    shopt -u dotglob
    rm -Rf code

    bash ./install.sh

    find $ZATO_TARGET_DIR/. -name *.pyc -exec rm -f {} \;
    rm -f ./code/hotfixman.sh
    rm -rf ./code/hotfixes
    rm -rf ./code/.git
    cd $CURDIR

}

function build_deb {

    mkdir $CURDIR/BUILDROOT
    mkdir $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH
    mkdir $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/opt
    mkdir $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH$ZATO_ROOT_DIR
    mkdir $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/etc
    mkdir $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/etc/bash_completion.d

    cd $CURDIR
    cp -r ../bash_completion/zato $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/etc/bash_completion.d/
    cp -r ../init_scripts/etc $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/
    cp -r ../init_scripts/lib $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/

    cp -r $ZATO_TARGET_DIR $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH$ZATO_TARGET_DIR
    cp -r $SOURCE_DIR/DEBIAN $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH
    cd $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH

    find . -path './DEBIAN' -prune -o -type f -exec md5sum {} + | sed -e 's/.\/opt/opt/g' > $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/md5sums
    SIZE=`du -sk $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/opt |awk '{print $1}'`

    sed "s/Version: VER/Version: $ZATO_VERSION-$PACKAGE_VERSION/g" $SOURCE_DIR/DEBIAN/control | sed "s/Architecture: ARCH/Architecture: $ARCH/g" | sed "s/Installed-Size: SIZE/Installed-Size: $SIZE/g" > $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/control
    sed -i "s/LIBUMFPACK_VERSION/$LIBUMFPACK_VERSION/g" $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/control
    sed -i "s/RELEASE_NAME/$RELEASE_NAME/g" $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/control
    sed -i "s/ZATO_VERSION/$ZATO_VERSION/g" $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/postinst
    sed -i "s/ZATO_VERSION/$ZATO_VERSION/g" $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/postrm


    cd $CURDIR/BUILDROOT
    dpkg-deb --build zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH

    mv $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH.deb $CURDIR/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH-$RELEASE_NAME.deb
}

cleanup
checkout
install_zato
build_deb

