#!/bin/bash

ZATO_ROOT=/opt/zato
BST_ROOT=zato-labs/bst
ZATO_ENV=env/qs-1

ZATO_SERVER_PATH=("$@")

cd /opt/zato
ZATO_VERSION=`ls | sort -n | tail -1`

if [ ! -d $ZATO_ROOT/zato-labs ]
then
    git clone https://github.com/zatosource/zato-labs.git
fi

echo "Compiling BST..."
cd $ZATO_ROOT/$BST_ROOT
make

echo "Symlinking Python dependencies..."
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

# Generate a random password...
echo "Generating a random password and saving it to a file..."
uuidgen > $ZATO_ROOT/random_password.txt
# ...and replace a variable with the password.
sed -i 's/$BST_PASSWORD/'\"$(cat $ZATO_ROOT/random_password.txt)\"'/g' \
       $ZATO_ROOT/$BST_ROOT/bst-enmasse.json

# Servers have to be stopped before proceeding
for SERVER_PATH in "$@"
do
    echo "Stopping Zato server..."
    zato stop $SERVER_PATH
done

for SERVER_PATH in "$@"
do
    echo "Preparing a directory to store BST definitions..."
    mkdir -p $SERVER_PATH/config/repo/proc/bst

    echo "Copying sample BST definitions..."
    cp $ZATO_ROOT/$BST_ROOT/sample.txt $SERVER_PATH/config/repo/proc/bst

    echo "Starting Zato server..."
    zato start $SERVER_PATH
    sleep 60

    echo "Hot-deploying BST services..."
    cp $ZATO_ROOT/$BST_ROOT/src/zato/bst/services.py $SERVER_PATH/pickup-dir
    sleep 60

    echo "Reconfiguring Zato server..."
    sed -i '/startup_services_first_worker/a \
        labs.proc.bst.definition.startup-setup=' \
        $SERVER_PATH/config/repo/server.conf

    echo "Importing REST channels and their credentials..."
    zato enmasse $SERVER_PATH/ \
         --input $ZATO_ROOT/$BST_ROOT/bst-enmasse.json \
         --import --replace-odb-objects
done

echo "Getting a list of BST deifnitions installed in a cluster..."
curl http://bst:`cat $ZATO_ROOT/random_password.txt`@localhost:11223/bst/get-definition-list
