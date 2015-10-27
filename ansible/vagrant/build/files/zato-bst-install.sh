#!/bin/bash

ZATO_ROOT=/opt/zato
BST_ROOT=zato-labs/bst
ZATO_ENV=env/qs-1

cd /opt/zato
ZATO_VERSION=`ls | sort -n | tail -1`

zato stop $ZATO_ROOT/$ZATO_ENV/server1
zato stop $ZATO_ROOT/$ZATO_ENV/server2

if [ ! -d $ZATO_ROOT/zato-labs ]
then
    git clone https://github.com/zatosource/zato-labs.git
fi

cd $ZATO_ROOT/$BST_ROOT
make

ln -s $ZATO_ROOT/$BST_ROOT/bst-env/lib/python2.7/site-packages/blockdiag \
      $ZATO_ROOT/$ZATO_VERSION/zato_extra_paths
ln -s $ZATO_ROOT/$BST_ROOT/bst-env/lib/python2.7/site-packages/funcparserlib \
      $ZATO_ROOT/$ZATO_VERSION/zato_extra_paths
ln -s $ZATO_ROOT/$BST_ROOT/bst-env/lib/python2.7/site-packages/PIL \
      $ZATO_ROOT/$ZATO_VERSION/zato_extra_paths
ln -s $ZATO_ROOT/$BST_ROOT/bst-env/lib/python2.7/site-packages/webcolors.py \
      $ZATO_ROOT/$ZATO_VERSION/zato_extra_paths
ln -s $ZATO_ROOT/$BST_ROOT/src/zato/bst/__init__.py \
      $ZATO_ROOT/$ZATO_VERSION/zato_extra_paths/zato_bst.py

mkdir -p $ZATO_ROOT/$ZATO_ENV/server1/config/repo/proc/bst
mkdir -p $ZATO_ROOT/$ZATO_ENV/server2/config/repo/proc/bst

cp $ZATO_ROOT/$BST_ROOT/sample.txt $ZATO_ROOT/$ZATO_ENV/server1/config/repo/proc/bst
cp $ZATO_ROOT/$BST_ROOT/sample.txt $ZATO_ROOT/$ZATO_ENV/server2/config/repo/proc/bst

zato start $ZATO_ROOT/$ZATO_ENV/server1
sleep 10
zato start $ZATO_ROOT/$ZATO_ENV/server2
sleep 10

cp $ZATO_ROOT/$BST_ROOT/src/zato/bst/services.py $ZATO_ROOT/$ZATO_ENV/server1/pickup-dir
sleep 10
cp $ZATO_ROOT/$BST_ROOT/src/zato/bst/services.py $ZATO_ROOT/$ZATO_ENV/server2/pickup-dir
sleep 10

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
$ZATO_ROOT/$ZATO_ENV/server1/config/repo/server.conf

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
$ZATO_ROOT/$ZATO_ENV/server2/config/repo/server.conf

# Generate a random password...
uuidgen > $ZATO_ROOT/random_password.txt
# ...and replace a variable with the password.
sed -i 's/$BST_PASSWORD/'\"$(cat $ZATO_ROOT/random_password.txt)\"'/g' \
       $ZATO_ROOT/$BST_ROOT/bst-enmasse.json

zato enmasse $ZATO_ROOT/$ZATO_ENV/server1/ \
     --input $ZATO_ROOT/$BST_ROOT/bst-enmasse.json \
     --import --replace-odb-objects
zato enmasse $ZATO_ROOT/$ZATO_ENV/server2/ \
     --input $ZATO_ROOT/$BST_ROOT/bst-enmasse.json \
     --import --replace-odb-objects

curl http://bst:`cat $ZATO_ROOT/random_password.txt`@localhost:11223/bst/get-definition-list
