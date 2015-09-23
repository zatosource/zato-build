#!/bin/bash

# Create Zato test repository
distributions=( wheezy jessie precise trusty )


echo 'Creating repositories...'

for distribution in "${distributions[@]}"
do
    sudo -u aptly -H aptly repo create -distribution=$distribution zato-stable-$distribution
done

echo 'Done.'
