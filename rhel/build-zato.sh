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
TMP_DIR=/opt/tmp
RPM_BUILD_DIR=/root/rpmbuild

RHEL_VERSION=el6
ARCH=`uname -i`

ZATO_ROOT_DIR=/opt/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION

PYTHON_VERSION=2.7.6rc1
PYTHON_ARCH_EXTENSION=tar.bz2
PYTHON_SRC_DIR=$TMP_DIR/Python-$PYTHON_VERSION

echo Building RHEL RPM zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH

function cleanup {
    rm -rf $TMP_DIR
    rm -rf $ZATO_TARGET_DIR

    rm -rf $CURDIR/config.log
    rm -rf $CURDIR/config.status
    rm -rf $CURDIR/Grammar
    rm -rf $CURDIR/Mac
    rm -rf $CURDIR/Makefile
    rm -rf $CURDIR/Makefile.pre
    rm -rf $CURDIR/Misc
    rm -rf $CURDIR/Modules
    rm -rf $CURDIR/Objects
    rm -rf $CURDIR/Parser
    rm -rf $CURDIR/pyconfig.h
    rm -rf $CURDIR/Python
    rm -rf $CURDIR/build
    rm -rf $CURDIR/Include
    rm -rf $CURDIR/libpython2.7.a
    rm -rf $CURDIR/pybuilddir.txt
    rm -rf $CURDIR/python
    rm -rf $CURDIR/python-gdb.py

    rm -rf $RPM_BUILD_DIR/BUILDROOT
}

function unpack {
    mkdir -p $TMP_DIR
    #mkdir -p $ZATO_TARGET_DIR

    #tar -C $TMP_DIR -xvf $SOURCE_DIR/zato-$ZATO_VERSION.tar.bz2 &> /dev/null
    tar -C $TMP_DIR -xvf $SOURCE_DIR/Python-$PYTHON_VERSION.$PYTHON_ARCH_EXTENSION &> /dev/null
    #mv $TMP_DIR/zato-$ZATO_VERSION/* $ZATO_TARGET_DIR
    #rm -rf $TMP_DIR/zato-$ZATO_VERSION/
}

function install_python {
    cd $CURDIR
    $PYTHON_SRC_DIR/configure --prefix=$ZATO_TARGET_DIR
    make -f $CURDIR/Makefile && make -f $CURDIR/Makefile altinstall

    ln -s $ZATO_TARGET_DIR/bin/python2.7 $ZATO_TARGET_DIR/bin/python2
    ln -s $ZATO_TARGET_DIR/bin/python2.7 $ZATO_TARGET_DIR/bin/python
    strip -s $ZATO_TARGET_DIR/bin/python2.7
}

function checkout_zato {
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

    #rm -rf $TMP_DIR
    #rm -rf $ZATO_TARGET_DIR

    #cd $ZATO_TARGET_DIR
    #curl -O https://zato.io/hotfixes/hotfixman.sh && bash hotfixman.sh
    #/bin/cp $SOURCE_DIR/_install-fedora.sh $ZATO_TARGET_DIR
    #sh ./install.sh
    #find $ZATO_TARGET_DIR/. -name *.pyc -exec rm -f {} \;
    #cd $CURDIR

    sudo mkdir -p $ZATO_TARGET_DIR
    sudo chown $USER $ZATO_TARGET_DIR

    git clone https://github.com/zatosource/zato.git $ZATO_TARGET_DIR
    cd $ZATO_TARGET_DIR

    for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
        git branch --track ${branch#remotes/origin/} $branch
    done
    
    git checkout $BRANCH_NAME

    cp $SOURCE_DIR/_install-fedora.sh $ZATO_TARGET_DIR/code
    cd $ZATO_TARGET_DIR/code
    bash ./install.sh
    find $ZATO_TARGET_DIR/code -name *.pyc -exec rm -f {} \;

}

function build_rpm {
    yum install rpm-build rpmdevtools
    rpmdev-setuptree

    rm -f $SOURCE_DIR/zato.spec
    cp $SOURCE_DIR/zato.spec.template $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_VERSION/$ZATO_VERSION/g" $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_RELEASE/$PACKAGE_VERSION.$RHEL_VERSION/g" $SOURCE_DIR/zato.spec
    cp $SOURCE_DIR/zato.spec $RPM_BUILD_DIR/SPECS/

    mkdir $RPM_BUILD_DIR/BUILDROOT
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/opt
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH$ZATO_ROOT_DIR
    cp -r $ZATO_TARGET_DIR $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH$ZATO_TARGET_DIR
    cd $RPM_BUILD_DIR/SPECS
    rpmbuild -ba zato.spec 

}

cleanup
unpack
checkout_zato
install_python
#install_zato
#build_rpm

