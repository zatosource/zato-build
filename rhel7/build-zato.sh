#!/bin/bash

set -x
[[ -z "$USER" ]] && USER=`whoami`

function usage(){
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

if [[ "$1" == "-h" || "$1" == "--help" ]] ; then
    usage
    exit 0
fi

if [[ -z "$1" ]] ; then
    echo Argument 1 must be the branch name from zatosource/zato used to build the package.
    exit 1
fi

if [[ -z "$2" || -z "$(echo $2| grep -E '^[0-9]+\.[0-9]+\.[0-9]+')" ]] ; then
    echo Argument 2 must be the Zato version to build.
    exit 1
fi

if [[ -z "$3" || -z "$(echo $3| grep -E '^python[2,3]?\.?')" ]] ; then
    echo Argument 3 must be the Python executable to use e.g. python, python2 or python3.
    exit 1
fi

if [[ -n "$4" && -z "$(echo $4| grep -E '^(stable|alpha|beta|pre|rc)')" ]] ; then
    echo Argument 4 is the release level of the build. The value has to be empty or be one of: stable, alpha, beta, pre or rc.
    exit 1
fi

BRANCH_NAME=$1
ZATO_VERSION=$2
PY_BINARY=$3
[[ -n "$4" ]] && PACKAGE_VERSION_SUFFIX="_${4}"
TRAVIS_PROCESS_NAME=$5

if ! [ -x "$(command -v $PY_BINARY)" ]; then
    if [[ "$PY_BINARY" == "python3" ]]; then
        sudo yum install -y centos-release-scl-rh
        sudo yum-config-manager --enable centos-sclo-rh-testing

        # On RHEL, enable RHSCL and RHSCL-beta repositories for you system:
        sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
        sudo yum-config-manager --enable rhel-server-rhscl-beta-7-rpms

        # 2. Install the collection:
        sudo yum install -y rh-python36

        # 3. Start using software collections:
        # scl enable rh-python36 bash
        source /opt/rh/rh-python36/enable
    else
        sudo yum install -y $PY_BINARY
    fi
fi

# Python 2 dependencies
PYTHON_DEPENDENCIES=""
PACKAGE_VERSION="python27${PACKAGE_VERSION_SUFFIX}"
if [[ $(${PY_BINARY} -c 'import sys; print(sys.version_info[:][0])') -eq 3 ]]
then
    # Python 3 dependencies
    PYTHON_DEPENDENCIES=", rh-python36, rh-python36-python-pip"
    PACKAGE_VERSION="python3${PACKAGE_VERSION_SUFFIX}"

    sudo yum install -y centos-release-scl-rh
    sudo yum-config-manager --enable centos-sclo-rh-testing

    # On RHEL, enable RHSCL and RHSCL-beta repositories for you system:
    sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
    sudo yum-config-manager --enable rhel-server-rhscl-beta-7-rpms

    # 2. Install the collection:
    sudo yum install -y rh-python36

    # 3. Start using software collections:
    # scl enable rh-python36 bash
    source /opt/rh/rh-python36/enable
fi

CURDIR="${BASH_SOURCE[0]}";RL="readlink";([[ `uname -s`=='Darwin' ]] || RL="$RL -f")
while([ -h "${CURDIR}" ]) do CURDIR=`$RL "${CURDIR}"`; done
N="/dev/null";pushd .>$N;cd `dirname ${CURDIR}`>$N;CURDIR=`pwd`;popd>$N

SOURCE_DIR=$CURDIR/package-base
TMP_DIR=$CURDIR/tmp
HOME=${HOME:-$CURDIR}
RPM_BUILD_DIR=$HOME/rpmbuild

RHEL_VERSION=el7
ARCH=`uname -i`

ZATO_ROOT_DIR=/opt/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION


echo Building RHEL RPM zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH

function prepare {
  sudo yum install -y rpm-build rpmdevtools wget
  rpmdev-setuptree
}

function cleanup {
    rm -rf $TMP_DIR
    sudo rm -rf $ZATO_TARGET_DIR
    rm -rf $RPM_BUILD_DIR/BUILDROOT
}

function checkout_zato {
    sudo mkdir -p $ZATO_TARGET_DIR
    sudo chown $USER $ZATO_TARGET_DIR

    git clone --depth 1 --no-single-branch https://github.com/zatosource/zato.git $ZATO_TARGET_DIR
    cd $ZATO_TARGET_DIR

    for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
      git branch --track ${branch#remotes/origin/} $branch
    done

    git checkout $BRANCH_NAME
}

function install_zato {
    cd $ZATO_TARGET_DIR/code
    sed -i -e 's|pg8000==1.13.1|pg8000==1.12.5|' -e 's|pyasn1==0.4.5|pyasn1==0.4.8|' requirements.txt
    sed -i -e 's|bzr==2.6.0|bzr==2.7.0|' _req_py27.txt
    ./install.sh -p ${PY_BINARY}
    run_tests_zato || exit 1
    find $ZATO_TARGET_DIR/. -name *.pyc -exec rm -f {} \;
    find $ZATO_TARGET_DIR/. ! -perm /004 -exec chmod 644 {} \;
}

function run_tests_zato {
    for f in zato-server zato-cy;do
        pushd $i
        make run-tests || exit 1
        popd
    done
    pushd zato-sso
        make sso-test || exit 1
    popd
}

function build_rpm {
    rm -f $SOURCE_DIR/zato.spec
    cp $SOURCE_DIR/zato.spec.template $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_VERSION/$ZATO_VERSION/g" $SOURCE_DIR/zato.spec
    sed -i.bak "s/ZATO_RELEASE/$PACKAGE_VERSION.$RHEL_VERSION/g" $SOURCE_DIR/zato.spec
    cat $SOURCE_DIR/zato.spec
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
    cp -r ../init_scripts/etc $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/
    cp -r ../init_scripts/lib $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH/
    cp -r $ZATO_TARGET_DIR $RPM_BUILD_DIR/BUILDROOT/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH$ZATO_TARGET_DIR
    cd $RPM_BUILD_DIR/SPECS
    rpmbuild -ba zato.spec

    if [[ -n $TRAVIS_PROCESS_NAME && $TRAVIS_PROCESS_NAME == "travis" ]]; then
        [[ -d /tmp/packages/$RHEL_VERSION/ ]] || mkdir -p /tmp/packages/$RHEL_VERSION/
        mv /root/rpmbuild/RPMS/x86_64/zato-$ZATO_VERSION-$PACKAGE_VERSION.$RHEL_VERSION.$ARCH.rpm /tmp/packages/$RHEL_VERSION/
    fi
}

prepare
cleanup
checkout_zato
install_zato
build_rpm
