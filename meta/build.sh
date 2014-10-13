#!/bin/bash

if [[ -z "$1" ]]
then
echo Argument 1 must be release version
    exit 1
fi

if [[ -z "$2" ]]
then
echo Argument 2 must be package version
    exit 2
fi

if [[ -z "$3" ]]
then
echo Argument 3 must be branch name
    exit 3
fi

if [[ -z "$4" ]]
then
echo Argument 4 must be distro directory or pattern
    exit 4
fi

RELEASE_VERSION=$1
PACKAGE_VERSION=$2
BRANCH_NAME=$3
PATTERN=$4

CURDIR="${BASH_SOURCE[0]}";RL="readlink";([[ `uname -s`=='Darwin' ]] || RL="$RL -f")
while([ -h "${CURDIR}" ]) do CURDIR=`$RL "${CURDIR}"`; done
N="/dev/null";pushd .>$N;cd `dirname ${CURDIR}`>$N;CURDIR=`pwd`;popd>$N


function prepare {
cd $CURDIR/vm

if [ "$PATTERN" = "all" ]; then
  systems=`ls -d * 2>&1`
else
  systems=`ls -d $PATTERN 2>&1`
  if echo $systems | grep -q "ls:"
   then
    echo Unrecognized pattern parameter
    exit 4
  fi
fi
echo Building packages zato-$RELEASE_VERSION-$PACKAGE_VERSION for $systems
}

function cleanup {
echo "Cleaning synced catalogues..."
for system in $systems
 do
  cd $CURDIR/vm/$system
  vagrant destroy --force
  rm -rf ./.vagrant
  rm -rf ./vagrant*
  rm -rf ./d*
  rm -rf ./synced/*
  rm -rf ./synced/.git*
  rm -f ./Vagrantfile
  rm -f ./Vagrantfile.bak
  echo "$system - done"
 done
}


function checkout_zato {

  for system in $systems
   do
    if echo "$system" | grep -q redhat
     then
	PACKAGE="rhel"
     elif echo "$system" | grep -q "debian\|ubuntu"
      then
	PACKAGE="deb"
    fi

    cd $CURDIR/vm/$system
    cp ./Vagrantfile.template ./Vagrantfile
    BRANCH_NAME=${BRANCH_NAME////'\/'}
    sed -i.bak "s#ARGS#$BRANCH_NAME $RELEASE_VERSION $PACKAGE_VERSION#g" ./Vagrantfile
    sed -i.bak "s#RPMVER#$RELEASE_VERSION-$PACKAGE_VERSION#g" ./Vagrantfile
    git clone https://github.com/zatosource/zato-build.git ./synced
   done
}

function build_packages {

  for system in $systems
   do
    cd $CURDIR/vm/$system
    vagrant up
    echo "Copying Zato packages to output directories"
    if ls $CURDIR/vm/$system/synced/deb/*.deb >/dev/null 2>&1; then
	/bin/cp $CURDIR/vm/$system/synced/deb/*.deb $CURDIR/output/$system
    fi
    if ls $CURDIR/vm/$system/synced/rhel/*.rpm >/dev/null 2>&1; then
	/bin/cp $CURDIR/vm/$system/synced/rhel/*.rpm $CURDIR/output/$system
    fi
    vagrant halt
   done
}



prepare
cleanup
checkout_zato
build_packages
