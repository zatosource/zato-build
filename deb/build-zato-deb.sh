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
ARCH=`uname -i`

ZATO_ROOT_DIR=/opt/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

echo Building `lsb_release -is` DEB zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH

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
    cp -r $ZATO_TARGET_DIR $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH$ZATO_TARGET_DIR
    cp -r $SOURCE_DIR/DEBIAN $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH
    cd $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH
    find . -path './DEBIAN' -prune -o -type f -exec md5sum {} + | sed -e 's/.\/opt/opt/g' > $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/md5sums
    SIZE=`du -sk $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/opt |awk '{print $1}'`
    sed "s/Version: VER/Version: $ZATO_VERSION-$PACKAGE_VERSION/g" $SOURCE_DIR/DEBIAN/control | sed "s/Architecture: ARCH/Architecture: $ARCH/g" | sed "s/Installed-Size: SIZE/Installed-Size: $SIZE/g" > $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH/DEBIAN/control
    cd $CURDIR/BUILDROOT
    dpkg-deb --build zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH
    mv $CURDIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION\_$ARCH.deb $CURDIR
}

cleanup
checkout
install_zato
build_deb

