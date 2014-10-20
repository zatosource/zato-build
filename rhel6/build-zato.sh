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

PYTHON_VERSION=2.7.6
PYTHON_ARCH_EXTENSION=tgz
PYTHON_SRC_DIR=$TMP_DIR/Python-$PYTHON_VERSION
PYTHON_BUILD_DIR=$CURDIR/python-build

echo Building RHEL RPM zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH

function prepare {
  yum install -y rpm-build rpmdevtools wget
  rpmdev-setuptree
}

function cleanup {
    rm -rf $TMP_DIR
    rm -rf $ZATO_TARGET_DIR
    rm -rf $PYTHON_BUILD_DIR
    rm -rf $RPM_BUILD_DIR/BUILDROOT
}

function download_python {
    mkdir -p $TMP_DIR
    cd $TMP_DIR
    wget -c https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.$PYTHON_ARCH_EXTENSION
    tar -xvf ./Python-$PYTHON_VERSION.$PYTHON_ARCH_EXTENSION &> /dev/null
}

function install_python {
    cd $TMP_DIR
    $PYTHON_SRC_DIR/configure --prefix=$ZATO_TARGET_DIR/code
    make -f $TMP_DIR/Makefile && make -f $TMP_DIR/Makefile altinstall

    ln -s $ZATO_TARGET_DIR/code/bin/python2.7 $ZATO_TARGET_DIR/code/bin/python2
    ln -s $ZATO_TARGET_DIR/code/bin/python2.7 $ZATO_TARGET_DIR/code/bin/python
    strip -s $ZATO_TARGET_DIR/code/bin/python2.7
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
    cp $SOURCE_DIR/_install-fedora.sh $ZATO_TARGET_DIR/code
    cd $ZATO_TARGET_DIR/code
    bash ./install.sh
    find $ZATO_TARGET_DIR/. -name *.pyc -exec rm -f {} \;
}

function build_rpm {
    rm -f $SOURCE_DIR/zato.spec
    cp $SOURCE_DIR/zato.spec.template $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_VERSION/$ZATO_VERSION/g" $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_RELEASE/$PACKAGE_VERSION.$RHEL_VERSION/g" $SOURCE_DIR/zato.spec
    mkdir -p $RPM_BUILD_DIR/SPECS/
    cp $SOURCE_DIR/zato.spec $RPM_BUILD_DIR/SPECS/

    mkdir $RPM_BUILD_DIR/BUILDROOT
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/opt
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH$ZATO_ROOT_DIR
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/etc
    mkdir $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/etc/bash_completion.d
    cd $CURDIR
    cp -r ../bash_completion/zato $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/etc/bash_completion.d/
    cp -r $ZATO_TARGET_DIR $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH$ZATO_TARGET_DIR
    cd $RPM_BUILD_DIR/SPECS
    rpmbuild -ba zato.spec
}

prepare
cleanup
download_python
checkout_zato
install_python
install_zato
build_rpm
