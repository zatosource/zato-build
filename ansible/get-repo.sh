#!/bin/bash

REPO=zato-build

# Clone the repo if it doesn't exist, or pull it if it does
if [ ! -d $repo  ]
then
    echo "Cloning zato-build repository..."
    sleep 1
    git clone git@github.com:zatosource/$REPO.git
    git fetch origin u/ddmx
    echo ""
    sleep 1
else
    echo "Pulling from zato-build repository..."
    sleep 1
    cd $repo
    git checkout u/ddmx
    git pull
    echo ""
    sleep 1
fi
